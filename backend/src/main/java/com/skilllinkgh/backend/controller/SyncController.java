package com.skilllinkgh.backend.controller;

import com.skilllinkgh.backend.dto.SyncRequest;
import com.skilllinkgh.backend.service.SyncService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

/**
 * Called by Firebase Cloud Functions to keep PostgreSQL in sync with Firestore.
 * Secured to ROLE_ADMIN only (see SecurityConfig).
 */
@RestController
@RequestMapping("/api/sync")
@RequiredArgsConstructor
public class SyncController {

    private final SyncService syncService;

    @PostMapping("/posts")
    public ResponseEntity<Void> syncPost(@RequestBody SyncRequest req) {
        syncService.upsertPost(req);
        return ResponseEntity.ok().build();
    }

    @PostMapping("/reels")
    public ResponseEntity<Void> syncReel(@RequestBody SyncRequest req) {
        syncService.upsertReel(req);
        return ResponseEntity.ok().build();
    }

    @DeleteMapping("/posts/{id}")
    public ResponseEntity<Void> deletePost(@PathVariable String id) {
        syncService.deletePost(id);
        return ResponseEntity.ok().build();
    }

    @DeleteMapping("/reels/{id}")
    public ResponseEntity<Void> deleteReel(@PathVariable String id) {
        syncService.deleteReel(id);
        return ResponseEntity.ok().build();
    }
}
