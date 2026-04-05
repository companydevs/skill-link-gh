package com.skilllinkgh.backend.model;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;
import java.util.List;

/**
 * Mirrors the Firestore 'posts' collection.
 * Synced here so the recommendation engine can score and rank posts
 * using PostgreSQL queries rather than Firestore scans.
 */
@Entity
@Table(name = "posts")
@Data
@NoArgsConstructor
public class Post {

    @Id
    @Column(name = "firestore_id", nullable = false, unique = true)
    private String firestoreId;   // same as Firestore doc ID

    @Column(name = "artisan_id", nullable = false)
    private String artisanId;

    @Column(name = "artisan_name")
    private String artisanName;

    @Column(name = "artisan_image")
    private String artisanImage;

    @Column(name = "service_category")
    private String serviceCategory;

    @Column(columnDefinition = "TEXT")
    private String description;

    private String pricing;

    // Engagement counters (kept in sync via interaction events)
    @Column(nullable = false)
    private int likes = 0;

    @Column(nullable = false)
    private int comments = 0;

    @Column(nullable = false)
    private int saves = 0;

    @Column(nullable = false)
    private int views = 0;

    // Artisan location at time of posting
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
