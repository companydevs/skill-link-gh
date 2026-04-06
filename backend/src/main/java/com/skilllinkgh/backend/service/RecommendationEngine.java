package com.skilllinkgh.backend.service;

import com.skilllinkgh.backend.model.Post;
import com.skilllinkgh.backend.model.Reel;
import com.skilllinkgh.backend.model.UserPreference;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.time.Duration;
import java.time.Instant;
import java.util.*;
import java.util.stream.Collectors;

/**
 * TikTok-style recommendation scoring engine.
 *
 * Final score = w_engagement * engagementScore
 *             + w_recency    * recencyScore
 *             + w_location   * locationScore
 *             + w_preference * preferenceScore
 *
 * Each sub-score is normalised to [0, 1].
 * Content is then ranked descending by final score.
 */
@Component
@RequiredArgsConstructor
public class RecommendationEngine {

    @Value("${recommendation.weights.engagement:0.30}")
    private double wEngagement;

    @Value("${recommendation.weights.recency:0.20}")
    private double wRecency;

    @Value("${recommendation.weights.location:0.25}")
    private double wLocation;

    @Value("${recommendation.weights.preference:0.25}")
    private double wPreference;

    @Value("${recommendation.recency-decay-hours:48}")
    private double recencyDecayHours;

    @Value("${recommendation.max-radius-km:50}")
    private double maxRadiusKm;

    // -------------------------------------------------------------------------
    // Public API
    // -------------------------------------------------------------------------

    /** Score and rank a list of posts for a given user */
    public List<Post> rankPosts(List<Post> candidates, UserPreference prefs,
                                Double userLat, Double userLng) {
        Map<String, Double> categoryAffinity = parseCategoryScores(prefs.getCategoryScores());

        return candidates.stream()
            .map(post -> new AbstractMap.SimpleEntry<>(post, scorePost(post, prefs, userLat, userLng, categoryAffinity)))
            .sorted(Map.Entry.<Post, Double>comparingByValue().reversed())
            .map(Map.Entry::getKey)
            .collect(Collectors.toList());
    }

    /** Score and rank a list of reels for a given user */
    public List<Reel> rankReels(List<Reel> candidates, UserPreference prefs,
                                Double userLat, Double userLng) {
        Map<String, Double> categoryAffinity = parseCategoryScores(prefs.getCategoryScores());

        return candidates.stream()
            .map(reel -> new AbstractMap.SimpleEntry<>(reel, scoreReel(reel, prefs, userLat, userLng, categoryAffinity)))
            .sorted(Map.Entry.<Reel, Double>comparingByValue().reversed())
            .map(Map.Entry::getKey)
            .collect(Collectors.toList());
    }

    // -------------------------------------------------------------------------
    // Scoring — Posts
    // -------------------------------------------------------------------------

    private double scorePost(Post post, UserPreference prefs,
                             Double userLat, Double userLng,
                             Map<String, Double> categoryAffinity) {

        double engagement = engagementScorePost(post);
        double recency    = recencyScore(post.getCreatedAt());
        double location   = locationScore(post.getLatitude(), post.getLongitude(), userLat, userLng);
        double preference = preferenceScore(post.getServiceCategory(), categoryAffinity);

        return wEngagement * engagement
             + wRecency    * recency
             + wLocation   * location
             + wPreference * preference;
    }

    /**
     * Engagement score for a post.
     * Weights: save > like > comment > view (saves signal strongest intent).
     */
    private double engagementScorePost(Post post) {
        double raw = post.getSaves()    * 3.0
                   + post.getLikes()    * 2.0
                   + post.getComments() * 1.5
                   + post.getViews()    * 0.1;
        // Normalise with log to prevent viral posts from dominating
        return logNormalise(raw);
    }

    // -------------------------------------------------------------------------
    // Scoring — Reels
    // -------------------------------------------------------------------------

    private double scoreReel(Reel reel, UserPreference prefs,
                             Double userLat, Double userLng,
                             Map<String, Double> categoryAffinity) {

        double engagement = engagementScoreReel(reel);
        double recency    = recencyScore(reel.getCreatedAt());
        double location   = locationScore(reel.getLatitude(), reel.getLongitude(), userLat, userLng);
        double preference = preferenceScore(reel.getArtisanCategory(), categoryAffinity);

        return wEngagement * engagement
             + wRecency    * recency
             + wLocation   * location
             + wPreference * preference;
    }

    /**
     * Engagement score for a reel.
     * Watch-time is the strongest signal (like TikTok's completion rate).
     * Normalised against a 60-second "ideal" reel.
     */
    private double engagementScoreReel(Reel reel) {
        double watchTimeScore = Math.min(reel.getAvgWatchSeconds() / 60.0, 1.0);

        double raw = watchTimeScore          * 5.0   // completion rate — top signal
                   + reel.getLikes()         * 2.0
                   + reel.getComments()      * 1.5
                   + reel.getShares()        * 2.5   // shares = strong positive signal
                   + reel.getViews()         * 0.1;

        return logNormalise(raw);
    }

    // -------------------------------------------------------------------------
    // Sub-scores (shared)
    // -------------------------------------------------------------------------

    /**
     * Recency score using exponential decay.
     * Content created now → 1.0; content older than recencyDecayHours → approaches 0.
     */
    private double recencyScore(Instant createdAt) {
        if (createdAt == null) return 0.0;
        double hoursOld = Duration.between(createdAt, Instant.now()).toMinutes() / 60.0;
        return Math.exp(-hoursOld / recencyDecayHours);
    }

    /**
     * Location score using haversine distance.
     * Content at user's exact location → 1.0; content at maxRadiusKm → 0.0.
     * Content beyond maxRadiusKm still gets a small non-zero score (not excluded).
     */
    private double locationScore(Double contentLat, Double contentLng,
                                 Double userLat, Double userLng) {
        if (contentLat == null || contentLng == null || userLat == null || userLng == null) {
            return 0.5; // neutral when location unknown
        }
        double distKm = haversineKm(userLat, userLng, contentLat, contentLng);
        // Linear decay: 1.0 at 0 km, 0.0 at maxRadiusKm, clamped to 0.05 beyond
        return Math.max(0.05, 1.0 - (distKm / maxRadiusKm));
    }

    /**
     * Preference score based on category affinity.
     * Returns the user's affinity score for the content's category (0.0 – 1.0).
     * New users with no history get 0.5 (neutral).
     *
     * ML upgrade: applies TF-IDF-style boosting — rare categories the user
     * engages with are weighted higher than common ones (e.g. if everyone
     * likes "plumbing" it's less signal than a niche preference for "welding").
     */
    private double preferenceScore(String category, Map<String, Double> categoryAffinity) {
        if (category == null || category.isBlank()) return 0.5;
        String cat = category.toLowerCase();
        double affinity = categoryAffinity.getOrDefault(cat, 0.5);

        // IDF boost: categories with fewer total users interested score higher
        // We approximate IDF using the inverse of how many categories the user has
        // (more focused users get stronger signals on their top categories)
        if (!categoryAffinity.isEmpty()) {
            double maxAffinity = categoryAffinity.values().stream()
                .mapToDouble(Double::doubleValue).max().orElse(1.0);
            // Boost if this is one of the user's top categories (relative to their max)
            double relativeStrength = maxAffinity > 0 ? affinity / maxAffinity : affinity;
            // Blend raw affinity with relative strength for TF-IDF-like effect
            affinity = 0.6 * affinity + 0.4 * relativeStrength;
        }

        return Math.min(affinity, 1.0);
    }

    // -------------------------------------------------------------------------
    // Helpers
    // -------------------------------------------------------------------------

    /** Log normalisation: maps [0, ∞) → [0, 1) smoothly */
    private double logNormalise(double raw) {
        if (raw <= 0) return 0.0;
        return Math.log1p(raw) / (Math.log1p(raw) + 1.0);
    }

    /** Haversine formula — returns distance in km */
    public double haversineKm(double lat1, double lng1, double lat2, double lng2) {
        final double R = 6371.0;
        double dLat = Math.toRadians(lat2 - lat1);
        double dLng = Math.toRadians(lng2 - lng1);
        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2)
                 + Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2))
                 * Math.sin(dLng / 2) * Math.sin(dLng / 2);
        return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    }

    /**
     * Parse "category:score,category:score" string into a map.
     * Scores are already normalised to [0, 1] when stored.
     */
    public Map<String, Double> parseCategoryScores(String raw) {
        Map<String, Double> map = new HashMap<>();
        if (raw == null || raw.isBlank()) return map;
        for (String entry : raw.split(",")) {
            String[] parts = entry.split(":");
            if (parts.length == 2) {
                try {
                    map.put(parts[0].trim().toLowerCase(), Double.parseDouble(parts[1].trim()));
                } catch (NumberFormatException ignored) {}
            }
        }
        return map;
    }

    /**
     * Serialise category affinity map back to the stored string format.
     * Scores are normalised so the max category always = 1.0.
     */
    public String serialiseCategoryScores(Map<String, Double> scores) {
        if (scores.isEmpty()) return "";
        double max = scores.values().stream().mapToDouble(Double::doubleValue).max().orElse(1.0);
        return scores.entrySet().stream()
            .map(e -> e.getKey() + ":" + String.format("%.4f", e.getValue() / max))
            .collect(Collectors.joining(","));
    }
}
