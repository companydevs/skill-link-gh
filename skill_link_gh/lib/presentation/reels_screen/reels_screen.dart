import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../domain/models/reel_model.dart';
import '../../notifier/reels_notifier.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/custom_app_toast.dart';
import 'widgets/reel_video_player_widget.dart';

class ReelsScreen extends ConsumerStatefulWidget {
  const ReelsScreen({super.key});

  @override
  ConsumerState<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends ConsumerState<ReelsScreen> {
  final ImagePicker _picker = ImagePicker();
  int _currentIndex = 0;

  bool _isUploading = false;
  double _uploadProgress = 0;

  @override
  void initState() {
    super.initState();
    ref.read(reelsProvider.notifier).loadInitialReels();
  }

  Future<void> _pickVideo() async {
    final XFile? video =
        await _picker.pickVideo(source: ImageSource.gallery);
    if (video == null) return;

    _uploadReel(video, 'New reel');
  }

  Future<void> _uploadReel(XFile video, String description) async {
    try {
      setState(() => _isUploading = true);

      final user = FirebaseAuth.instance.currentUser!;
      final file = File(video.path);

      final refStorage = FirebaseStorage.instance.ref(
        'reels/${user.uid}_${DateTime.now().millisecondsSinceEpoch}.mp4',
      );

      final task = refStorage.putFile(file);

      task.snapshotEvents.listen((snapshot) {
        setState(() {
          _uploadProgress =
              snapshot.bytesTransferred / snapshot.totalBytes;
        });
      });

      final snap = await task;
      final videoUrl = await snap.ref.getDownloadURL();

      final result = await FirebaseFunctions.instance
          .httpsCallable('createReel')
          .call({
        'videoUrl': videoUrl,
        'description': description,
      });

      ref.read(reelsProvider.notifier).addReel(
            Reel(
              id: result.data['reelId'],
              videoUrl: videoUrl,
              artisanName: user.displayName ?? '',
              artisanAvatar: user.photoURL ?? '',
              artisanCategory: '',
              artisanSemanticLabel: '',
              description: description,
              likes: 0,
              comments: 0,
              shares: 0,
              isLiked: false,
              timestamp: DateTime.now(),
            ),
          );

      AppToast.show(context, message: 'Reel uploaded');
    } catch (_) {
      AppToast.show(context, message: 'Upload failed');
    } finally {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final reels = ref.watch(reelsProvider);

    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.black,
          body: PageView.builder(
            scrollDirection: Axis.vertical,
            itemCount: reels.length,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            itemBuilder: (_, index) {
              final reel = reels[index];

              return ReelVideoPlayerWidget(
                videoUrl: reel.videoUrl,
                isActive: index == _currentIndex,
                isMuted: true,
              );
            },
          ),
          bottomNavigationBar: const CustomBottomBar(currentIndex: 1),
          floatingActionButton: FloatingActionButton(
            onPressed: _pickVideo,
            child: const Icon(Icons.add),
          ),
        ),

        if (_isUploading)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(value: _uploadProgress),
          ),
      ],
    );
  }
}
