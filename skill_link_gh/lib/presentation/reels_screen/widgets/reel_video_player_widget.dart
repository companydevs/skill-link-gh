// widgets/reel_video_player_widget.dart
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class ReelVideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final bool isActive;
  final bool isMuted;
  final VoidCallback? onVideoError;

  const ReelVideoPlayerWidget({
    super.key,
    required this.videoUrl,
    required this.isActive,
    required this.isMuted,
    this.onVideoError,
  });

  @override
  State<ReelVideoPlayerWidget> createState() => _ReelVideoPlayerWidgetState();
}

class _ReelVideoPlayerWidgetState extends State<ReelVideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  void _initializeVideo() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      if (widget.videoUrl.isEmpty) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Video URL is empty';
          _isLoading = false;
        });
        return;
      }

      Uri? parsedUri;
      try {
        parsedUri = Uri.parse(widget.videoUrl);
        if (!parsedUri.hasScheme ||
            (!parsedUri.isScheme('http') && !parsedUri.isScheme('https'))) {
          throw FormatException('Invalid URL scheme');
        }
      } catch (e) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Invalid video URL format';
          _isLoading = false;
        });
        return;
      }

      _controller = VideoPlayerController.networkUrl(
        parsedUri,
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: true,
          allowBackgroundPlayback: false,
        ),
      );

      await _controller.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _hasError = false;
          _isLoading = false;
        });

        _controller.setLooping(true);
        _controller.setVolume(widget.isMuted ? 0.0 : 1.0);

        if (widget.isActive) {
          _controller.play();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
          _errorMessage = 'Failed to load video: ${e.toString()}';
          _isInitialized = false;
        });
      }
    }
  }

  @override
  void didUpdateWidget(ReelVideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.videoUrl != widget.videoUrl) {
      if (_isInitialized) {
        _controller.dispose();
      }
      _isInitialized = false;
      _hasError = false;
      _initializeVideo();
      return;
    }

    if (oldWidget.isActive != widget.isActive && _isInitialized && !_hasError) {
      if (widget.isActive) {
        _controller.play();
      } else {
        _controller.pause();
      }
    }

    if (oldWidget.isMuted != widget.isMuted && _isInitialized && !_hasError) {
      _controller.setVolume(widget.isMuted ? 0.0 : 1.0);
    }
  }

  @override
  void dispose() {
    if (_isInitialized) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError && !_isLoading) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.white70, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Video failed to load',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized || _isLoading) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Center(
          child: AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          ),
        ),
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.transparent,
                Colors.black26,
                Colors.black54,
              ],
              stops: [0.0, 0.5, 0.8, 1.0],
            ),
          ),
        ),
        if (_controller.value.isBuffering)
          Container(
            color: Colors.black26,
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
          ),
      ],
    );
  }
}
