package com.skilllinkgh.backend.model;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;
import java.util.HashSet;
import java.util.Set;

/**
 * Stores per-user preference signals used by the recommendation engine.
 * Updated automatically as users interact with posts and reels.
 */
@Entity
@Table(name = "user_preferences")
@Data
@NoArgsConstructor
public class UserPreference {

    @Id
    @Column(name = "user_id", nullable = false)
    private String userId;   // Firebase UID

    // Last known location of the user (updated on each feed request)
    @Column(name = "last_lat")
    private Double lastLat;

    @Column(name = "last_lng")
    private Double lastLng;

    @Column(name = "preferred_radius_km")
    private double preferredRadiusKm = 10.0;

    /**
     * Category affinity scores: category → score (0.0 – 1.0).
     * Stored as a simple comma-separated "category:score" string for portability.
     * Example: "plumbing:0.8,electrical:0.5,carpentry:0.3"
     */
    @Column(name = "category_scores", columnDefinition = "TEXT")
    private String categoryScores = "";

    // Aggregate interaction counts (used to normalise affinity scores)
    @Column(name = "total_likes")
    private int totalLikes = 0;

    @Column(name = "total_saves")
    private int totalSaves = 0;

    @Column(name = "total_bookings")
    private int totalBookings = 0;

    @Column(name = "total_skips")
    private int totalSkips = 0;

    @Column(name = "total_views")
    private int totalViews = 0;

    @Column(name = "updated_at")
    private Instant updatedAt;
}
