// screens/reels_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import 'package:skill_link_gh/provider/reels_provider.dart';
import 'package:skill_link_gh/widgets/custom_bottom_bar.dart';
import 'package:skill_link_gh/utils/fix_negative_likes.dart';
import './widgets/reel_info_overlay_widget.dart';
import './widgets/reel_interaction_overlay_widget.dart';
import './widgets/reel_video_player_widget.dart';
import './widgets/comments_bottom_sheet.dart';

class ReelsScreen extends ConsumerStatefulWidget {
  const ReelsScreen({super.key});

  @override
  ConsumerState<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends ConsumerState<ReelsScreen> {
  final PageController _pageController = PageController();
  int _currentReelIndex = 0;
  bool _isMuted = true;

  final TextEditingController _captionController = TextEditingController();

  // Debouncing: prevent multiple rapid likes
  final Set<String> _likingReels = {};

  // Like animation state
  bool _showLikeAnimation = false;
  String? _animatingReelId;

  // Preload cache for next video
  void _preloadVideo(String videoUrl) {
    debugPrint(
      '⏩ Preloading next video: ${videoUrl.substring(videoUrl.length - 20)}',
    );
    // Simple preload - just create controller in background
    Future.microtask(() async {
      try {
        final uri = Uri.parse(videoUrl);
        if (!uri.hasScheme) return;

        final controller = VideoPlayerController.networkUrl(
          uri,
          videoPlayerOptions: VideoPlayerOptions(
            mixWithOthers: true,
            allowBackgroundPlayback: false,
          ),
        );

        await controller.initialize();
        debugPrint(
          '✅ Preload complete: ${videoUrl.substring(videoUrl.length - 20)}',
        );
        // Controller will be cached by video player widget
      } catch (e) {
        debugPrint('⚠️ Preload failed: $e');
        // Preload failed, no big deal
      }
    });
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    // Fix negative likes on first load
    FixNegativeLikes.fixAll();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reelsNotifierProvider.notifier).loadInitialReels();
    });
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _pageController.dispose();
    _captionController.dispose();
    super.dispose();
  }

  /// Instant like function with animation
  void _handleLike(String reelId) {
    // Prevent multiple likes on the same reel
    if (_likingReels.contains(reelId)) {
      return;
    }

    _likingReels.add(reelId);

    // Show animation
    setState(() {
      _showLikeAnimation = true;
      _animatingReelId = reelId;
    });

    // Hide animation after delay
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _showLikeAnimation = false;
          _animatingReelId = null;
        });
      }
    });

    // Perform the like instantly
    ref
        .read(reelsNotifierProvider.notifier)
        .toggleLike(reelId)
        .then((_) {
          _likingReels.remove(reelId);
        })
        .catchError((e) {
          _likingReels.remove(reelId);
        });
  }

  Future<void> _pickAndUploadVideo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickVideo(source: ImageSource.gallery);

    if (pickedFile == null || !mounted) return;

    final file = File(pickedFile.path);

    // Validate file exists and has content
    if (!file.existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selected file does not exist")),
      );
      return;
    }

    final fileSize = file.lengthSync();
    if (fileSize == 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Selected file is empty")));
      return;
    }

    // Show uploading dialog with progress
    double uploadProgress = 0.0;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Uploading Reel..."),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Processing your video (${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB)",
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(value: uploadProgress),
              const SizedBox(height: 8),
              Text("${(uploadProgress * 100).toInt()}%"),
            ],
          ),
        ),
      ),
    );

    try {
      final repository = ref.read(reelsRepositoryProvider);

      final videoUrl = await repository.uploadVideo(file, (progress) {
        if (mounted) {
          uploadProgress = progress;
        }
      });

      final description = _captionController.text.trim().isEmpty
          ? "Check out my latest work! ✨"
          : _captionController.text.trim();

      await repository.createReel(videoUrl: videoUrl, description: description);

      // Refresh reels list
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            ref.read(reelsNotifierProvider.notifier).refreshReels();
          }
        });
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Reel uploaded successfully! 🎉")),
        );
        _captionController.clear();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Upload failed: ${e.toString()}")),
        );
      }
    }
  }

  void _showCommentsBottomSheet(BuildContext context, reel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          CommentsBottomSheet(reelId: reel.id, reelAuthor: reel.artisanName),
    );
  }

  void _showUploadSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Create New Reel",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _captionController,
                decoration: const InputDecoration(
                  hintText: "Write a caption...",
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _pickAndUploadVideo();
                },
                icon: const Icon(Icons.video_library),
                label: const Text("Select Video & Upload"),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reelsAsync = ref.watch(reelsNotifierProvider);
    final theme = Theme.of(context);

    // Trigger load if we have empty data
    if (reelsAsync.hasValue && reelsAsync.value!.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(reelsNotifierProvider.notifier).loadInitialReels();
      });
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main content based on AsyncValue state
          reelsAsync.when(
            loading: () {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            },
            error: (error, stack) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.white70,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Failed to load reels",
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        ref.read(reelsNotifierProvider.notifier).refreshReels();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            },
            data: (reels) {
              if (reels.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.video_library_outlined,
                        color: Colors.white70,
                        size: 80,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        "No reels yet",
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Be the first to share your craft!",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  await ref.read(reelsNotifierProvider.notifier).refreshReels();
                },
                color: Colors.white,
                backgroundColor: Colors.black54,
                child: PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  itemCount: reels.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentReelIndex = index;
                    });

                    // Preload next video
                    if (index + 1 < reels.length) {
                      final nextReel = reels[index + 1];
                      _preloadVideo(nextReel.videoUrl);
                    }

                    if (index >= reels.length - 2) {
                      final notifier = ref.read(reelsNotifierProvider.notifier);
                      if (notifier.hasMoreReels && !notifier.isLoadingMore) {
                        Future.microtask(() {
                          notifier.loadMoreReels();
                        });
                      }
                    }
                  },
                  itemBuilder: (context, index) {
                    final reel = reels[index];
                    final isActive = _currentReelIndex == index;

                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        ReelVideoPlayerWidget(
                          videoUrl: reel.videoUrl,
                          isActive: isActive,
                          isMuted: _isMuted,
                        ),
                        // Double tap to like with animation
                        GestureDetector(
                          onDoubleTap: () {
                            HapticFeedback.mediumImpact();
                            if (!reel.isLiked) {
                              _handleLike(reel.id);
                            }
                          },
                          child: Container(color: Colors.transparent),
                        ),
                        // Like animation overlay
                        if (_showLikeAnimation && _animatingReelId == reel.id)
                          Center(
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.elasticOut,
                              builder: (context, value, child) {
                                return Transform.scale(
                                  scale: value,
                                  child: Opacity(
                                    opacity: 1.0 - (value * 0.5),
                                    child: Icon(
                                      Icons.favorite,
                                      color: Colors.white,
                                      size: 100,
                                      shadows: [
                                        Shadow(
                                          color: Colors.red.withValues(
                                            alpha: 0.8,
                                          ),
                                          blurRadius: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        // Info overlay - positioned at bottom like TikTok
                        Positioned(
                          left: 16,
                          bottom: 20,
                          right: 80,
                          child: ReelInfoOverlayWidget(
                            artisanName: reel.artisanName,
                            artisanAvatar: reel.artisanAvatar,
                            artisanAvatarSemanticLabel:
                                reel.artisanSemanticLabel,
                            category: reel.artisanCategory,
                            description: reel.description,
                            onProfileTap: () {
                              Navigator.pushNamed(
                                context,
                                '/artisan-profile-screen',
                              );
                            },
                          ),
                        ),
                        // Interaction overlay - positioned at bottom
                        Positioned(
                          right: 12,
                          bottom: 20,
                          child: ReelInteractionOverlayWidget(
                            likes: reel.likes,
                            comments: reel.comments,
                            shares: reel.shares,
                            isLiked: reel.isLiked,
                            onLikeTap: () {
                              HapticFeedback.mediumImpact();
                              _handleLike(reel.id);
                            },
                            onCommentTap: () {
                              _showCommentsBottomSheet(context, reel);
                            },
                            onShareTap: () {},
                            onBookServiceTap: () {
                              Navigator.pushNamed(
                                context,
                                '/service-booking-screen',
                              );
                            },
                          ),
                        ),
                        // Mute button - adjusted position
                        Positioned(
                          right: 16,
                          top: MediaQuery.of(context).padding.top + 80,
                          child: IconButton(
                            icon: Icon(
                              _isMuted ? Icons.volume_off : Icons.volume_up,
                              color: Colors.white,
                              size: 28,
                            ),
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              setState(() => _isMuted = !_isMuted);
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              );
            },
          ),

          // Loading indicator for more reels
          Consumer(
            builder: (context, ref, child) {
              final notifier = ref.read(reelsNotifierProvider.notifier);
              if (notifier.isLoadingMore) {
                return Positioned(
                  bottom: 50,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Loading more...',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // Top bar with title and camera
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Reels',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _showUploadSheet();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomBar(currentIndex: 1),
    );
  }
}
