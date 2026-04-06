package com.skilllinkgh.backend.dto;

import lombok.Builder;
import lombok.Data;

import java.util.List;
import java.util.Map;

/**
 * Payload returned by GET /api/admin/analytics
 * Consumed by the React admin dashboard.
 */
@Data
@Builder
public class AnalyticsResponse {

    // ── Recommendation engine stats ──────────────────────────────────────
    /** Total interaction events recorded */
    private long totalInteractions;

    /** Breakdown by interaction type: LIKE, SAVE, SKIP, VIEW, BOOK … */
    private Map<String, Long> interactionBreakdown;

    /** Top 10 categories by positive engagement (likes + saves + bookings) */
    private List<CategoryStat> topCategories;

    /** Total unique users who have a preference profile */
    private long usersWithPreferences;

    /** Average number of interactions per user */
    private double avgInteractionsPerUser;

    // ── Content stats ────────────────────────────────────────────────────
    private long totalPosts;
    private long totalReels;

    /** Top 5 most-liked posts */
    private List<ContentStat> topPosts;

    /** Top 5 most-liked reels */
    private List<ContentStat> topReels;

    // ── Nested types ─────────────────────────────────────────────────────

    @Data
    @Builder
    public static class CategoryStat {
        private String category;
        private long engagementCount;
    }

    @Data
    @Builder
    public static class ContentStat {
        private String firestoreId;
        private String title;
        private String artisanName;
        private int likes;
        private int comments;
        private int views;
    }
}
