package com.skilllinkgh.backend.controller;

import com.skilllinkgh.backend.dto.InteractionRequest;
import com.skilllinkgh.backend.model.UserInteraction;
import com.skilllinkgh.backend.service.UserPreferenceService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.time.Instant;

@RestController
@RequestMapping("/api/interactions")
@RequiredArgsConstructor
public class InteractionController {

    private final UserPreferenceService prefService;

    /**
     * POST /api/interactions
     * Records a user interaction (like, view, skip, save, book, etc.)
     * and updates the user's preference profile automatically.
     *
     * Body: { contentId, contentType, interactionType, watchSeconds? }
     */
    @PostMapping
    public ResponseEntity<Void> recordInteraction(
            @AuthenticationPrincipal String userId,
            @Valid @RequestBody InteractionRequest req) {

        UserInteraction interaction = new UserInteraction();
        interaction.setUserId(userId);
        interaction.setContentId(req.getContentId());
        interaction.setContentType(req.getContentType());
        interaction.setInteractionType(req.getInteractionType());
        interaction.setWatchSeconds(req.getWatchSeconds());
        interaction.setCreatedAt(Instant.now());

        // Category is resolved server-side from the content record
        // (avoids trusting client-supplied category)
        prefService.processInteraction(interaction);

        return ResponseEntity.ok().build();
    }
}
