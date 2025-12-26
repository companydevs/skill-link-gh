// screens/reels_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:skill_link_gh/provider/reels_provider.dart'; // Your notifier/provider file
import 'package:skill_link_gh/widgets/custom_bottom_bar.dart';
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

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    // Load initial reels after the widget tree is built
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

      print("Starting video upload for file: ${file.path}");

      final videoUrl = await repository.uploadVideo(file, (progress) {
        if (mounted) {
          // Update progress in dialog
          uploadProgress = progress;
        }
      });

      print("Video uploaded successfully. URL: $videoUrl");

      final description = _captionController.text.trim().isEmpty
          ? "Check out my latest work! ✨"
          : _captionController.text.trim();

      print("Creating reel with description: $description");

      await repository.createReel(videoUrl: videoUrl, description: description);

      print("Reel created successfully");

      // Refresh reels list after a small delay to ensure widget tree is stable
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            ref.read(reelsNotifierProvider.notifier).refreshReels();
          }
        });
      }

      if (mounted) {
        Navigator.pop(context); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Reel uploaded successfully! 🎉")),
        );
        _captionController.clear();
      }
    } catch (e) {
      print("Upload error: $e");
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

    print("🎬 ReelsScreen build called, state: ${reelsAsync.runtimeType}");

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main content based on AsyncValue state
          reelsAsync.when(
            loading: () {
              print("⏳ Showing loading state");
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Loading reels...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              );
            },
            error: (error, stack) {
              print("❌ Showing error state: $error");
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
              print("📊 Showing data state with ${reels.length} reels");
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

                    // Optimized preloading: load more when nearing end with smaller chunks
                    if (index >= reels.length - 2) {
                      // Reduced threshold for faster loading
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
                        // Double tap to like
                        GestureDetector(
                          onDoubleTap: () {
                            HapticFeedback.mediumImpact();
                            Future.microtask(() {
                              ref
                                  .read(reelsNotifierProvider.notifier)
                                  .toggleLike(reel.id, reel.isLiked);
                            });
                          },
                          child: Container(color: Colors.transparent),
                        ),
                        // Info overlay
                        Positioned(
                          left: 16,
                          bottom: 100,
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
                        // Interaction overlay
                        Positioned(
                          right: 12,
                          bottom: 100,
                          child: ReelInteractionOverlayWidget(
                            likes: reel.likes,
                            comments: reel.comments,
                            shares: reel.shares,
                            isLiked: reel.isLiked,
                            onLikeTap: () {
                              HapticFeedback.mediumImpact();
                              Future.microtask(() {
                                ref
                                    .read(reelsNotifierProvider.notifier)
                                    .toggleLike(reel.id, reel.isLiked);
                              });
                            },
                            onCommentTap: () {
                              _showCommentsBottomSheet(context, reel);
                            },
                            onShareTap: () {
                              // TODO: Share reel
                            },
                            onBookServiceTap: () {
                              Navigator.pushNamed(
                                context,
                                '/service-booking-screen',
                              );
                            },
                          ),
                        ),
                        // Mute button
                        Positioned(
                          right: 16,
                          bottom: 120,
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
                      child: Row(
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
                          const SizedBox(width: 8),
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
