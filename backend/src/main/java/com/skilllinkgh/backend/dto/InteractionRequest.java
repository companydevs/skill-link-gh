package com.skilllinkgh.backend.dto;

import com.skilllinkgh.backend.model.UserInteraction;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

/**
 * Sent by the Flutter app to record a user interaction event.
 */
@Data
public class InteractionRequest {

    @NotBlank
    private String contentId;

    @NotNull
    private UserInteraction.ContentType contentType;

    @NotNull
    private UserInteraction.InteractionType interactionType;

    /** Seconds watched — required for REEL VIEW / SKIP events */
    private Integer watchSeconds;
}
