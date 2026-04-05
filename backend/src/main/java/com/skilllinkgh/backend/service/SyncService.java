package com.skilllinkgh.backend.service;

import com.skilllinkgh.backend.dto.SyncRequest;
import com.skilllinkgh.backend.model.Post;
import com.skilllinkgh.backend.model.Reel;
import com.skilllinkgh.backend.repository.PostRepository;
import com.skilllinkgh.backend.repository.ReelRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;

/**
 * Keeps PostgreSQL in sync with Firestore.
 * Called by a Firebase Cloud Function (or admin process) on content create/update.
 */
@Service
@RequiredArgsConstructor
public class SyncService {

    private final PostRepository postRepo;
    private final ReelRepository reelRepo;

    @Transactional
    public Post upsertPost(SyncRequest req) {
        Post post = postRepo.findById(req.getFirestoreId()).orElse(new Post());
        post.setFirestoreId(req.getFirestoreId());
        post.setArtisanId(req.getArtisanId());
        post.setArtisanName(req.getArtisanName());
        post.setArtisanImage(req.getArtisanImage());
        post.setServiceCategory(req.getServiceCategory());
        post.setDescription(req.getDescription());
        post.setPricing(req.getPricing());
        post.setLikes(req.getLikes());
        post.setComments(req.getComments());
        post.setSaves(req.getSaves());
        post.setLatitude(req.getLatitude());
        post.setLongitude(req.getLongitude());
        post.setCity(req.getCity());
        post.setState(req.getState());
        post.setCreatedAt(req.getCreatedAt() != null ? req.getCreatedAt() : Instant.now());
        post.setUpdatedAt(Instant.now());
        post.setActive(true);
        return postRepo.save(post);
    }

    @Transactional
    public Reel upsertReel(SyncRequest req) {
        Reel reel = reelRepo.findById(req.getFirestoreId()).orElse(new Reel());
        reel.setFirestoreId(req.getFirestoreId());
        reel.setArtisanId(req.getArtisanId());
        reel.setArtisanName(req.getArtisanName());
        reel.setArtisanAvatar(req.getArtisanAvatar());
        reel.setArtisanCategory(req.getArtisanCategory());
        reel.setVideoUrl(req.getVideoUrl());
        reel.setDescription(req.getDescription());
        reel.setLikes(req.getLikes());
        reel.setComments(req.getComments());
        reel.setShares(req.getShares());
        reel.setAvgWatchSeconds(req.getAvgWatchSeconds());
        reel.setLatitude(req.getLatitude());
        reel.setLongitude(req.getLongitude());
        reel.setCity(req.getCity());
        reel.setState(req.getState());
        reel.setCreatedAt(req.getCreatedAt() != null ? req.getCreatedAt() : Instant.now());
        reel.setUpdatedAt(Instant.now());
        reel.setActive(true);
        return reelRepo.save(reel);
    }

    @Transactional
    public void deletePost(String firestoreId) {
        postRepo.findById(firestoreId).ifPresent(p -> { p.setActive(false); postRepo.save(p); });
    }

    @Transactional
    public void deleteReel(String firestoreId) {
        reelRepo.findById(firestoreId).ifPresent(r -> { r.setActive(false); reelRepo.save(r); });
    }
}
