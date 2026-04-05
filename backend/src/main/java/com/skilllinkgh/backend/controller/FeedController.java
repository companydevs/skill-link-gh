package com.skilllinkgh.backend.controller;

import com.skilllinkgh.backend.dto.FeedRequest;
import com.skilllinkgh.backend.model.Post;
import com.skilllinkgh.backend.model.Reel;
import com.skilllinkgh.backend.service.FeedService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/feed")
@RequiredArgsConstructor
public class FeedController {

    private final FeedService feedService;

    /**
     * GET /api/feed/posts
     * Returns a personalised, location-aware ranked list of posts.
     *
     * Query params (all optional):
     *   lat, lng       — user's current location
     *   radiusKm       — search radius (default: stored pref or 10km)
     *   lastContentId  — cursor for pagination
     *   pageSize       — items per page (default 10)
     */
    @GetMapping("/posts")
    public ResponseEntity<List<Post>> getPostFeed(
            @AuthenticationPrincipal String userId,
            @RequestParam(required = false) Double lat,
            @RequestParam(required = false) Double lng,
            @RequestParam(required = false) Double radiusKm,
            @RequestParam(required = false) String lastContentId,
            @RequestParam(defaultValue = "10") int pageSize) {

        FeedRequest req = new FeedRequest();
        req.setLatitude(lat);
        req.setLongitude(lng);
        req.setRadiusKm(radiusKm);
        req.setLastContentId(lastContentId);
        req.setPageSize(pageSize);

        return ResponseEntity.ok(feedService.getPostFeed(userId, req));
    }

    /**
     * GET /api/feed/reels
     * Returns a personalised, location-aware ranked list of reels.
     */
    @GetMapping("/reels")
    public ResponseEntity<List<Reel>> getReelFeed(
            @AuthenticationPrincipal String userId,
            @RequestParam(required = false) Double lat,
            @RequestParam(required = false) Double lng,
            @RequestParam(required = false) Double radiusKm,
            @RequestParam(required = false) String lastContentId,
            @RequestParam(defaultValue = "10") int pageSize) {

        FeedRequest req = new FeedRequest();
        req.setLatitude(lat);
        req.setLongitude(lng);
        req.setRadiusKm(radiusKm);
        req.setLastContentId(lastContentId);
        req.setPageSize(pageSize);

        return ResponseEntity.ok(feedService.getReelFeed(userId, req));
    }
}
