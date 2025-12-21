import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class ReelVideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final bool isActive;
  final bool isMuted;

  const ReelVideoPlayerWidget({
    super.key,
    required this.videoUrl,
    required this.isActive,
    required this.isMuted,
  });

  @override
  State<ReelVideoPlayerWidget> createState() => _ReelVideoPlayerWidgetState();
}

class _ReelVideoPlayerWidgetState extends State<ReelVideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _showMuteIcon = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  void _initVideo() {
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        _controller.setLooping(true);
        _controller.setVolume(widget.isMuted ? 0 : 1);

        if (widget.isActive) {
          _controller.play();
        }

        setState(() {});
      });
  }

  @override
  void didUpdateWidget(covariant ReelVideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.videoUrl != widget.videoUrl) {
      _controller.dispose();
      _initVideo();
      return;
    }

    if (widget.isActive) {
      _controller.play();
    } else {
      _controller.pause();
    }

    _controller.setVolume(widget.isMuted ? 0 : 1);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleMute() {
    final muted = _controller.value.volume == 0;
    _controller.setVolume(muted ? 1 : 0);

    setState(() => _showMuteIcon = true);

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _showMuteIcon = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return GestureDetector(
      onTap: _toggleMute,
      child: Stack(
        fit: StackFit.expand,
        children: [
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _controller.value.size.width,
              height: _controller.value.size.height,
              child: VideoPlayer(_controller),
            ),
          ),

          /// Gradient overlay (TikTok style)
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black26,
                  Colors.transparent,
                  Colors.black54,
                ],
              ),
            ),
          ),

          /// Mute indicator
          if (_showMuteIcon)
            Center(
              child: Icon(
                _controller.value.volume == 0
                    ? Icons.volume_off
                    : Icons.volume_up,
                size: 80,
                color: Colors.white70,
              ),
            ),

          /// Progress bar
          Positioned(
            bottom: 8,
            left: 16,
            right: 16,
            child: VideoProgressIndicator(
              _controller,
              allowScrubbing: false,
              colors: VideoProgressColors(
                playedColor: Colors.white,
                backgroundColor: Colors.white24,
                bufferedColor: Colors.white38,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
