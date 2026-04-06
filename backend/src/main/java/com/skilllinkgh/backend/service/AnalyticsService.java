package com.skilllinkgh.backend.service;

import com.skilllinkgh.backend.dto.AnalyticsResponse;
import com.skilllinkgh.backend.model.UserInteraction;
import com.skilllinkgh.backend.repository.PostRepository;
import com.skilllinkgh.backend.repository.ReelRepository;
import com.skilllinkgh.backend.repository.UserInteractionRepository;
import com.skilllinkgh.backend.repository.UserPreferenceRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class AnalyticsService {

    private final UserInteractionRepository interactionRepo;
    private final UserPreferenceRepository prefRepo;
    private final PostRepository postRepo;
    private final ReelRepository reelRepo;

    public AnalyticsResponse getAnalytics() {

        // Interaction breakdown by type
        List<Object[]> rawBreakdown = interactionRepo.countByInteractionType();
        Map<String, Long> breakdown = rawBreakdown.stream()
            .collect(Collectors.toMap(
                r -> r[0].toString(),
                r -> (Long) r[1]
            ));

        long totalInteractions = breakdown.values().stream().mapToLong(Long::longValue).sum();

        // Top categories
        List<Object[]> rawCats = interactionRepo.findTopCategories();
        List<AnalyticsResponse.CategoryStat> topCategories = rawCats.stream()
            .limit(10)
            .map(r -> AnalyticsResponse.CategoryStat.builder()
                .category(r[0].toString())
                .engagementCount((Long) r[1])
                .build())
            .collect(Collectors.toList());

        // Users with preferences
        long usersWithPrefs = prefRepo.count();

        // Avg interactions per user
        long distinctUsers = interactionRepo.countDistinctUsers();
        double avgInteractions = distinctUsers > 0 ? (double) totalInteractions / distinctUsers : 0;

        // Content counts
        long totalPosts = postRepo.count();
        long totalReels = reelRepo.count();

        // Top posts
        var topPosts = postRepo.findByActiveTrueOrderByCreatedAtDesc(PageRequest.of(0, 5))
            .stream()
            .map(p -> AnalyticsResponse.ContentStat.builder()
                .firestoreId(p.getFirestoreId())
                .title(p.getServiceCategory())
                .artisanName(p.getArtisanName())
                .likes(p.getLikes())
                .comments(p.getComments())
                .views(p.getViews())
                .build())
            .collect(Collectors.toList());

        // Top reels
        var topReels = reelRepo.findByActiveTrueOrderByCreatedAtDesc(PageRequest.of(0, 5))
            .stream()
            .map(r -> AnalyticsResponse.ContentStat.builder()
                .firestoreId(r.getFirestoreId())
                .title(r.getArtisanCategory())
                .artisanName(r.getArtisanName())
                .likes(r.getLikes())
                .comments(r.getComments())
                .views(r.getViews())
                .build())
            .collect(Collectors.toList());

        return AnalyticsResponse.builder()
            .totalInteractions(totalInteractions)
            .interactionBreakdown(breakdown)
            .topCategories(topCategories)
            .usersWithPreferences(usersWithPrefs)
            .avgInteractionsPerUser(avgInteractions)
            .totalPosts(totalPosts)
            .totalReels(totalReels)
            .topPosts(topPosts)
            .topReels(topReels)
            .build();
    }
}
