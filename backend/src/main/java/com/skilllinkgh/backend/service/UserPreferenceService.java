package com.skilllinkgh.backend.service;

import com.skilllinkgh.backend.model.UserInteraction;
import com.skilllinkgh.backend.model.UserPreference;
import com.skilllinkgh.backend.repository.UserInteractionRepository;
import com.skilllinkgh.backend.repository.UserPreferenceRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.HashMap;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class UserPreferenceService {

    private final UserPreferenceRepository prefRepo;
    private final UserInteractionRepository interactionRepo;
    private final RecommendationEngine engine;

    /**
     * Returns the user's preference profile, creating a default one if it doesn't exist.
     */
    public UserPreference getOrCreate(String userId) {
        return prefRepo.findByUserId(userId).orElseGet(() -> {
            UserPreference pref = new UserPreference();
            pref.setUserId(userId);
            pref.setUpdatedAt(Instant.now());
            return prefRepo.save(pref);
        });
    }

    /**
     * Updates the user's last known location.
     */
    @Transactional
    public void updateLocation(String userId, double lat, double lng) {
        UserPreference pref = getOrCreate(userId);
        pref.setLastLat(lat);
        pref.setLastLng(lng);
        pref.setUpdatedAt(Instant.now());
        prefRepo.save(pref);
    }

    /**
     * Processes a new interaction event and updates the user's category affinity scores.
     *
     * Interaction weights (how much each event shifts affinity):
     *   BOOK    → +5.0  (strongest signal — real money spent)
     *   SAVE    → +3.0
     *   LIKE    → +2.0
     *   COMMENT → +1.5
     *   SHARE   → +2.0
     *   VIEW    → +0.2
     *   SKIP    → -1.0  (negative signal)
     *   REPORT  → -3.0  (strong negative)
     *   UNLIKE  → -1.0
     *   UNSAVE  → -1.5
     */
    @Transactional
    public void processInteraction(UserInteraction interaction) {
        // Persist the raw event
        interactionRepo.save(interaction);

        if (interaction.getCategory() == null || interaction.getCategory().isBlank()) return;

        UserPreference pref = getOrCreate(interaction.getUserId());
        Map<String, Double> scores = new HashMap<>(engine.parseCategoryScores(pref.getCategoryScores()));

        String cat = interaction.getCategory().toLowerCase();
        double delta = interactionDelta(interaction.getInteractionType(), interaction.getWatchSeconds());

        scores.merge(cat, delta, Double::sum);
        // Clamp to [0, ∞) — scores can't go negative
        scores.replaceAll((k, v) -> Math.max(0.0, v));

        pref.setCategoryScores(engine.serialiseCategoryScores(scores));
        updateAggregateCounts(pref, interaction.getInteractionType());
        pref.setUpdatedAt(Instant.now());
        prefRepo.save(pref);
    }

    // -------------------------------------------------------------------------
    // Helpers
    // -------------------------------------------------------------------------

    private double interactionDelta(UserInteraction.InteractionType type, Integer watchSeconds) {
        return switch (type) {
            case BOOK    -> 5.0;
            case SAVE    -> 3.0;
            case LIKE    -> 2.0;
            case COMMENT -> 1.5;
            case SHARE   -> 2.0;
            case VIEW    -> watchSeconds != null ? Math.min(watchSeconds / 30.0, 1.0) * 0.5 : 0.2;
            case SKIP    -> -1.0;
            case REPORT  -> -3.0;
            case UNLIKE  -> -1.0;
            case UNSAVE  -> -1.5;
        };
    }

    private void updateAggregateCounts(UserPreference pref, UserInteraction.InteractionType type) {
        switch (type) {
            case LIKE    -> pref.setTotalLikes(pref.getTotalLikes() + 1);
            case SAVE    -> pref.setTotalSaves(pref.getTotalSaves() + 1);
            case BOOK    -> pref.setTotalBookings(pref.getTotalBookings() + 1);
            case SKIP    -> pref.setTotalSkips(pref.getTotalSkips() + 1);
            case VIEW    -> pref.setTotalViews(pref.getTotalViews() + 1);
            default      -> {}
        }
    }
}
