package com.skilllinkgh.backend.dto;

import lombok.Data;

/**
 * Sent by the Flutter app when requesting a personalised feed.
 */
@Data
public class FeedRequest {
    /** User's current latitude (optional — falls back to stored prefs) */
    private Double latitude;
    /** User's current longitude */
    private Double longitude;
    /** Preferred search radius in km (optional — uses stored pref or default 10km) */
    private Double radiusKm;
    /** Pagination cursor — firestoreId of the last item in the previous page */
    private String lastContentId;
    /** Number of items to return (default 10) */
    private int pageSize = 10;
}
