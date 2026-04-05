package com.skilllinkgh.backend.repository;

import com.skilllinkgh.backend.model.Post;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface PostRepository extends JpaRepository<Post, String> {

    /**
     * Fetch active posts within a bounding box (fast pre-filter before haversine scoring).
     * The actual distance scoring happens in the recommendation service.
     */
    @Query("""
        SELECT p FROM Post p
        WHERE p.active = true
          AND p.latitude  BETWEEN :minLat AND :maxLat
          AND p.longitude BETWEEN :minLng AND :maxLng
        ORDER BY p.createdAt DESC
    """)
    List<Post> findActivePostsInBoundingBox(
        @Param("minLat") double minLat,
        @Param("maxLat") double maxLat,
        @Param("minLng") double minLng,
        @Param("maxLng") double maxLng
    );

    /** Fallback: fetch recent active posts when user has no location */
    List<Post> findByActiveTrueOrderByCreatedAtDesc(org.springframework.data.domain.Pageable pageable);

    /** Fetch posts by a specific artisan */
    List<Post> findByArtisanIdAndActiveTrueOrderByCreatedAtDesc(String artisanId);
}
