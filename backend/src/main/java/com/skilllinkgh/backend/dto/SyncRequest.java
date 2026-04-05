package com.skilllinkgh.backend.dto;

import lombok.Data;

import java.time.Instant;
import java.util.List;

/**
 * Used to sync a post or reel from Firestore into PostgreSQL.
 * Called by a Cloud Function or admin process whenever content is created/updated.
 */
@Data
public class SyncRequest {

    // ---- shared fields ----
    private String firestoreId;
    private String artisanId;
    private String artisanName;
    private String serviceCategory;   // for posts
    private String artisanCategory;   // for reels
    private String description;
    private Double latitude;
    private Double longitude;
    private String city;
    private String state;
    private int likes;
    private int comments;
    private Instant createdAt;

    // ---- post-specific ----
    private String artisanImage;
    private String pricing;
    private int saves;

    // ---- reel-specific ----
    private String artisanAvatar;
    private String videoUrl;
    private int shares;
    private double avgWatchSeconds;
}
