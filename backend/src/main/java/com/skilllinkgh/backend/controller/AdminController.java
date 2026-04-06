package com.skilllinkgh.backend.controller;

import com.skilllinkgh.backend.dto.AnalyticsResponse;
import com.skilllinkgh.backend.service.AnalyticsService;
import com.skilllinkgh.backend.service.SeedService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/admin")
@RequiredArgsConstructor
@Tag(name = "Admin", description = "Analytics, seeding and admin operations")
public class AdminController {

    private final AnalyticsService analyticsService;
    private final SeedService seedService;

    /**
     * GET /api/admin/analytics
     * Returns recommendation engine stats, top categories, top content.
     * Consumed by the React admin dashboard.
     */
    @GetMapping("/analytics")
    @Operation(summary = "Get recommendation engine analytics")
    public ResponseEntity<AnalyticsResponse> getAnalytics() {
        return ResponseEntity.ok(analyticsService.getAnalytics());
    }

    /**
     * POST /api/admin/seed
     * Seeds demo interaction data so the algorithm visibly works in demos.
     * Only available in non-production environments.
     */
    @PostMapping("/seed")
    @Operation(summary = "Seed demo interaction data for presentations")
    public ResponseEntity<String> seed(@RequestParam(defaultValue = "50") int count) {
        seedService.seedInteractions(count);
        return ResponseEntity.ok("Seeded " + count + " interactions successfully");
    }
}
