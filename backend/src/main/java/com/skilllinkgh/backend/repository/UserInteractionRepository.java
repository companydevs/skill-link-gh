package com.skilllinkgh.backend.repository;

import com.skilllinkgh.backend.model.UserInteraction;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Set;

public interface UserInteractionRepository extends JpaRepository<UserInteraction, Long> {

    /** IDs of content the user has already seen (to exclude from feed) */
    @Query("""
        SELECT i.contentId FROM UserInteraction i
        WHERE i.userId = :userId
          AND i.contentType = :contentType
          AND i.interactionType IN ('VIEW', 'LIKE', 'SAVE', 'SKIP', 'BOOK')
    """)
    Set<String> findSeenContentIds(
        @Param("userId") String userId,
        @Param("contentType") UserInteraction.ContentType contentType
    );

    /** Category interaction counts for preference building */
    @Query("""
        SELECT i.category, COUNT(i) FROM UserInteraction i
        WHERE i.userId = :userId
          AND i.interactionType IN ('LIKE', 'SAVE', 'COMMENT', 'BOOK')
          AND i.category IS NOT NULL
        GROUP BY i.category
        ORDER BY COUNT(i) DESC
    """)
    List<Object[]> findCategoryAffinityRaw(@Param("userId") String userId);

    /** Recent interactions for a user (for preference refresh) */
    List<UserInteraction> findTop200ByUserIdOrderByCreatedAtDesc(String userId);
}
