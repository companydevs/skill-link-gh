package com.skilllinkgh.backend.service;

import com.skilllinkgh.backend.dto.FeedRequest;
import com.skilllinkgh.backend.model.Post;
import com.skilllinkgh.backend.model.Reel;
import com.skilllinkgh.backend.model.UserInteraction;
import com.skilllinkgh.backend.model.UserPreference;
import com.skilllinkgh.backend.repository.PostRepository;
import com.skilllinkgh.backend.repository.ReelRepository;
import com.skilllinkgh.backend.repository.UserInteractionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class FeedService {

    private final PostRepository postRepo;
    private final ReelRepository reelRepo;
    private final UserInteractionRepository interactionRepo;
    private final UserPreferenceService prefService;
    private final RecommendationEngine engine;

    @Value("${recommendation.max-radius-km:50}")
    private double maxRadiusKm;

    @Value("${recommendation.feed-page-size:10}")
    private int defaultPageSize;

    // -------------------------------------------------------------------------
    // Posts feed
    // -------------------------------------------------------------------------

    public List<Post> getPostFeed(String userId, FeedRequest req) {
        UserPreference prefs = prefService.getOrCreate(userId);

        // Use request location if provided, otherwise fall back to stored prefs
        Double lat = req.getLatitude() != null ? req.getLatitude() : prefs.getLastLat();
        Double lng = req.getLongitude() != null ? req.getLongitude() : prefs.getLastLng();

        // Update stored location if a fresh one was provided
        if (req.getLatitude() != null && req.getLongitude() != null) {
            prefService.updateLocation(userId, req.getLatitude(), req.getLongitude());
        }

        double radius = req.getRadiusKm() != null ? req.getRadiusKm() : prefs.getPreferredRadiusKm();
        int pageSize = req.getPageSize() > 0 ? req.getPageSize() : defaultPageSize;

        // Fetch candidates
        List<Post> candidates = fetchPostCandidates(lat, lng, radius, pageSize * 5);

        // Exclude already-seen content
        Set<String> seen = interactionRepo.findSeenContentIds(userId, UserInteraction.ContentType.POST);
        candidates = candidates.stream()
            .filter(p -> !seen.contains(p.getFirestoreId()))
            .collect(Collectors.toList());

        // Score and rank
        List<Post> ranked = engine.rankPosts(candidates, prefs, lat, lng);

        // Apply cursor-based pagination
        ranked = applyCursor(ranked, req.getLastContentId(), Post::getFirestoreId);

        return ranked.stream().limit(pageSize).collect(Collectors.toList());
    }

    // -------------------------------------------------------------------------
    // Reels feed
    // -------------------------------------------------------------------------

    public List<Reel> getReelFeed(String userId, FeedRequest req) {
        UserPreference prefs = prefService.getOrCreate(userId);

        Double lat = req.getLatitude() != null ? req.getLatitude() : prefs.getLastLat();
        Double lng = req.getLongitude() != null ? req.getLongitude() : prefs.getLastLng();

        if (req.getLatitude() != null && req.getLongitude() != null) {
            prefService.updateLocation(userId, req.getLatitude(), req.getLongitude());
        }

        double radius = req.getRadiusKm() != null ? req.getRadiusKm() : prefs.getPreferredRadiusKm();
        int pageSize = req.getPageSize() > 0 ? req.getPageSize() : defaultPageSize;

        List<Reel> candidates = fetchReelCandidates(lat, lng, radius, pageSize * 5);

        Set<String> seen = interactionRepo.findSeenContentIds(userId, UserInteraction.ContentType.REEL);
        candidates = candidates.stream()
            .filter(r -> !seen.contains(r.getFirestoreId()))
            .collect(Collectors.toList());

        List<Reel> ranked = engine.rankReels(candidates, prefs, lat, lng);
        ranked = applyCursor(ranked, req.getLastContentId(), Reel::getFirestoreId);

        return ranked.stream().limit(pageSize).collect(Collectors.toList());
    }

    // -------------------------------------------------------------------------
    // Candidate fetching
    // -------------------------------------------------------------------------

    private List<Post> fetchPostCandidates(Double lat, Double lng, double radiusKm, int limit) {
        if (lat == null || lng == null) {
            return postRepo.findByActiveTrueOrderByCreatedAtDesc(PageRequest.of(0, limit));
        }
        double[] bbox = boundingBox(lat, lng, radiusKm);
        List<Post> posts = postRepo.findActivePostsInBoundingBox(bbox[0], bbox[1], bbox[2], bbox[3]);

        // If the local area is sparse, pad with recent global posts
        if (posts.size() < limit / 2) {
            List<Post> global = postRepo.findByActiveTrueOrderByCreatedAtDesc(PageRequest.of(0, limit));
            posts.addAll(global);
            posts = posts.stream().distinct().limit(limit).collect(Collectors.toList());
        }
        return posts;
    }

    private List<Reel> fetchReelCandidates(Double lat, Double lng, double radiusKm, int limit) {
        if (lat == null || lng == null) {
            return reelRepo.findByActiveTrueOrderByCreatedAtDesc(PageRequest.of(0, limit));
        }
        double[] bbox = boundingBox(lat, lng, radiusKm);
        List<Reel> reels = reelRepo.findActiveReelsInBoundingBox(bbox[0], bbox[1], bbox[2], bbox[3]);

        if (reels.size() < limit / 2) {
            List<Reel> global = reelRepo.findByActiveTrueOrderByCreatedAtDesc(PageRequest.of(0, limit));
            reels.addAll(global);
            reels = reels.stream().distinct().limit(limit).collect(Collectors.toList());
        }
        return reels;
    }

    // -------------------------------------------------------------------------
    // Helpers
    // -------------------------------------------------------------------------

    /**
     * Approximate bounding box for a given centre + radius.
     * Returns [minLat, maxLat, minLng, maxLng].
     * 1 degree latitude ≈ 111 km.
     */
    private double[] boundingBox(double lat, double lng, double radiusKm) {
        double latDelta = radiusKm / 111.0;
        double lngDelta = radiusKm / (111.0 * Math.cos(Math.toRadians(lat)));
        return new double[]{lat - latDelta, lat + latDelta, lng - lngDelta, lng + lngDelta};
    }

    /** Cursor-based pagination: skip items up to and including lastContentId */
    private <T> List<T> applyCursor(List<T> items, String lastId, java.util.function.Function<T, String> idExtractor) {
        if (lastId == null || lastId.isBlank()) return items;
        int idx = -1;
        for (int i = 0; i < items.size(); i++) {
            if (lastId.equals(idExtractor.apply(items.get(i)))) {
                idx = i;
                break;
            }
        }
        return idx >= 0 ? items.subList(idx + 1, items.size()) : items;
    }
}
