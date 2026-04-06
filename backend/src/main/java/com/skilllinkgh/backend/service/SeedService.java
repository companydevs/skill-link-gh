package com.skilllinkgh.backend.service;

import com.skilllinkgh.backend.model.UserInteraction;
import com.skilllinkgh.backend.repository.PostRepository;
import com.skilllinkgh.backend.repository.ReelRepository;
import com.skilllinkgh.backend.repository.UserInteractionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Random;

/**
 * Seeds realistic demo interaction data so the recommendation algorithm
 * visibly learns and reorders content during presentations.
 */
@Service
@RequiredArgsConstructor
public class SeedService {

    private final UserInteractionRepository interactionRepo;
    private final PostRepository postRepo;
    private final ReelRepository reelRepo;
    private final UserPreferenceService prefService;

    private static final List<String> DEMO_USERS = List.of(
        "demo_user_1", "demo_user_2", "demo_user_3", "demo_user_4", "demo_user_5"
    );

    private static final List<String> CATEGORIES = List.of(
        "plumbing", "electrical", "carpentry", "painting", "masonry",
        "tailoring", "welding", "tiling", "cleaning", "landscaping"
    );

    public void seedInteractions(int count) {
        Random rng = new Random(42);

        var posts = postRepo.findAll();
        var reels = reelRepo.findAll();

        for (int i = 0; i < count; i++) {
            String userId = DEMO_USERS.get(rng.nextInt(DEMO_USERS.size()));
            String category = CATEGORIES.get(rng.nextInt(CATEGORIES.size()));

            // Pick random content
            boolean usePost = rng.nextBoolean() && !posts.isEmpty();
            String contentId;
            UserInteraction.ContentType contentType;

            if (usePost && !posts.isEmpty()) {
                var post = posts.get(rng.nextInt(posts.size()));
                contentId = post.getFirestoreId();
                contentType = UserInteraction.ContentType.POST;
                category = post.getServiceCategory() != null ? post.getServiceCategory() : category;
            } else if (!reels.isEmpty()) {
                var reel = reels.get(rng.nextInt(reels.size()));
                contentId = reel.getFirestoreId();
                contentType = UserInteraction.ContentType.REEL;
                category = reel.getArtisanCategory() != null ? reel.getArtisanCategory() : category;
            } else {
                contentId = "demo_content_" + rng.nextInt(20);
                contentType = UserInteraction.ContentType.POST;
            }

            // Weighted random interaction type (more likes/views than bookings)
            UserInteraction.InteractionType type = weightedInteractionType(rng);

            UserInteraction interaction = new UserInteraction();
            interaction.setUserId(userId);
            interaction.setContentId(contentId);
            interaction.setContentType(contentType);
            interaction.setInteractionType(type);
            interaction.setCategory(category);
            interaction.setCreatedAt(
                Instant.now().minus(rng.nextInt(72), ChronoUnit.HOURS)
            );
            if (type == UserInteraction.InteractionType.VIEW || type == UserInteraction.InteractionType.SKIP) {
                interaction.setWatchSeconds(type == UserInteraction.InteractionType.SKIP ? 1 : rng.nextInt(60) + 3);
            }

            prefService.processInteraction(interaction);
        }
    }

    private UserInteraction.InteractionType weightedInteractionType(Random rng) {
        int r = rng.nextInt(100);
        if (r < 40) return UserInteraction.InteractionType.VIEW;
        if (r < 60) return UserInteraction.InteractionType.LIKE;
        if (r < 70) return UserInteraction.InteractionType.SAVE;
        if (r < 78) return UserInteraction.InteractionType.COMMENT;
        if (r < 85) return UserInteraction.InteractionType.SKIP;
        if (r < 92) return UserInteraction.InteractionType.SHARE;
        return UserInteraction.InteractionType.BOOK;
    }
}
