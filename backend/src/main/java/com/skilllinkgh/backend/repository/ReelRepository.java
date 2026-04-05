package com.skilllinkgh.backend.repository;

import com.skilllinkgh.backend.model.Reel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface ReelRepository extends JpaRepository<Reel, String> {

    @Query("""
        SELECT r FROM Reel r
        WHERE r.active = true
          AND r.latitude  BETWEEN :minLat AND :maxLat
          AND r.longitude BETWEEN :minLng AND :maxLng
        ORDER BY r.createdAt DESC
    """)
    List<Reel> findActiveReelsInBoundingBox(
        @Param("minLat") double minLat,
        @Param("maxLat") double maxLat,
        @Param("minLng") double minLng,
        @Param("maxLng") double maxLng
    );

    List<Reel> findByActiveTrueOrderByCreatedAtDesc(org.springframework.data.domain.Pageable pageable);

    List<Reel> findByArtisanIdAndActiveTrueOrderByCreatedAtDesc(String artisanId);
}
