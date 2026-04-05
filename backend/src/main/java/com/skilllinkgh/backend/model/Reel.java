package com.skilllinkgh.backend.model;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;

/**
 * Mirrors the Firestore 'reels' collection.
 * Stored here for fast recommendation scoring.
 */
@Entity
@Table(name = "reels")
@Data
@NoArgsConstructor
public class Reel {

    @Id
    @Column(name = "firestore_id", nullable = false, unique = true)
    private String firestoreId;

    @Column(name = "artisan_id", nullable = false)
    private String artisanId;

    @Column(name = "artisan_name")
    private String artisanName;

    @Column(name = "artisan_avatar")
    private String artisanAvatar;

    @Column(name = "artisan_category")
    private String artisanCategory;

    @Column(name = "video_url", nullable = false, columnDefinition = "TEXT")
    private String videoUrl;

    @Column(columnDefinition = "TEXT")
    private String description;

    // Engagement counters
    @Column(nullable = false)
    private int likes = 0;

    @Column(nullable = false)
    private int comments = 0;

    @Column(nullable = false)
    private int shares = 0;

    @Column(nullable = false)
    private int views = 0;

    // Watch-time in seconds (avg across all viewers) — key TikTok signal
    @Column(name = "avg_watch_seconds")
    private double avgWatchSeconds = 0.0;

    // Artisan location
    private Double latitude;
    private Double longitude;
    private String city;
    private String state;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @Column(name = "updated_at")
    private Instant updatedAt;

    @Column(name = "is_active", nullable = false)
    private boolean active = true;
}
