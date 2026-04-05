package com.skilllinkgh.backend.model;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;

/**
 * Records every user interaction with a post or reel.
 * This is the raw event log that feeds the preference engine.
 */
@Entity
@Table(name = "user_interactions", indexes = {
    @Index(name = "idx_interaction_user", columnList = "user_id"),
    @Index(name = "idx_interaction_content", columnList = "content_id, content_type"),
    @Index(name = "idx_interaction_created", columnList = "created_at")
})
@Data
@NoArgsConstructor
public class UserInteraction {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", nullable = false)
    private String userId;

    @Column(name = "content_id", nullable = false)
    private String contentId;   // firestoreId of Post or Reel

    @Column(name = "content_type", nullable = false)
    @Enumerated(EnumType.STRING)
    private ContentType contentType;

    @Column(name = "interaction_type", nullable = false)
    @Enumerated(EnumType.STRING)
    private InteractionType interactionType;

    /** For reels: how many seconds the user watched before swiping */
    @Column(name = "watch_seconds")
    private Integer watchSeconds;

    /** Category of the content at time of interaction (denormalised for speed) */
    @Column(name = "category")
    private String category;

    /** Artisan's location at time of interaction */
    @Column(name = "content_lat")
    private Double contentLat;

    @Column(name = "content_lng")
    private Double contentLng;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    public enum ContentType {
        POST, REEL
    }

    public enum InteractionType {
        VIEW,       // user saw the content
        LIKE,       // liked
        UNLIKE,     // removed like
        SAVE,       // saved post
        UNSAVE,     // removed save
        COMMENT,    // left a comment
        SHARE,      // shared
        SKIP,       // swiped past quickly (< 2s watch time for reels)
        BOOK,       // booked the artisan from this content
        REPORT      // reported — negative signal
    }
}
