// Debug version of reel video player with extensive logging
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class DebugReelVideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final bool isActive;
  final bool isMuted;

  const DebugReelVideoPlayerWidget({
    super.key,
    required this.videoUrl,
    required this.isActive,
    required this.isMuted,
  });

  @override
  State<DebugReelVideoPlayerWidget> createState() =>
      _DebugReelVideoPlayerWidgetState();
}

class _DebugReelVideoPlayerWidgetState
    extends State<DebugReelVideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  String _errorMessage = '';
  String _debugInfo = '';

  @override
  void initState() {
    super.initState();
    _debugInfo = 'Initializing video player...';
    _initializeVideo();
  }

  void _initializeVideo() async {
    try {
      setState(() {
        _debugInfo = 'Validating URL: ${widget.videoUrl}';
      });

      // Validate URL first
      if (widget.videoUrl.isEmpty) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Video URL is empty';
          _debugInfo = 'ERROR: Empty URL';
        });
        return;
      }

      // Check if URL is valid
      Uri? uri;
      try {
        uri = Uri.parse(widget.videoUrl);
        setState(() {
          _debugInfo =
              'URL parsed successfully: ${uri?.host ?? 'unknown host'}';
        });
      } catch (e, stackTrace) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Invalid URL format: $e';
          _debugInfo = 'ERROR: Invalid URL format';
        });
        print('URL parsing error: $e');
        print('Stack trace: $stackTrace');
        return;
      }

      setState(() {
        _debugInfo = 'Creating VideoPlayerController...';
      });

      // Create controller with proper URI parsing
      _controller = VideoPlayerController.networkUrl(
        uri,
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: true,
          allowBackgroundPlayback: false,
        ),
      );

      setState(() {
        _debugInfo = 'Initializing video controller...';
      });

      // Initialize with extended timeout for larger files
      await _controller.initialize().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception(
            'Video initialization timeout after 30 seconds - large file or slow network',
          );
        },
      );

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _hasError = false;
          _debugInfo =
              'Video initialized successfully! Duration: ${_controller.value.duration}';
        });

        // Configure video settings
        _controller.setLooping(true);
        _controller.setVolume(widget.isMuted ? 0.0 : 1.0);

        // Auto-play if active
        if (widget.isActive) {
          _controller.play();
          setState(() {
            _debugInfo += '\nAuto-playing video...';
          });
        }
      }
    } catch (e, stackTrace) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to load video: ${e.toString()}';
          _debugInfo = 'ERROR: $e';
          _isInitialized = false;
        });
      }
      print('Video initialization error: $e');
      print('Stack trace: $stackTrace');
    }
  }

  @override
  void didUpdateWidget(DebugReelVideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle URL changes
    if (oldWidget.videoUrl != widget.videoUrl) {
      _controller.dispose();
      _isInitialized = false;
      _hasError = false;
      _debugInfo = 'URL changed, reinitializing...';
      _initializeVideo();
      return;
    }

    // Handle play/pause state changes
    if (oldWidget.isActive != widget.isActive && _isInitialized && !_hasError) {
      if (widget.isActive) {
        _controller.play();
        setState(() {
          _debugInfo += '\nPlaying video...';
        });
      } else {
        _controller.pause();
        setState(() {
          _debugInfo += '\nPausing video...';
        });
      }
    }

    // Handle mute/unmute changes
    if (oldWidget.isMuted != widget.isMuted && _isInitialized && !_hasError) {
      _controller.setVolume(widget.isMuted ? 0.0 : 1.0);
      setState(() {
        _debugInfo += '\nVolume: ${widget.isMuted ? 'Muted' : 'Unmuted'}';
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background
        Container(color: Colors.black),

        // Video player or error/loading state
        if (_hasError)
          _buildErrorState()
        else if (!_isInitialized)
          _buildLoadingState()
        else
          _buildVideoPlayer(),

        // Debug overlay (top-left corner)
        Positioned(
          top: 50,
          left: 10,
          right: 10,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'DEBUG INFO:',
                  style: const TextStyle(
                    color: Colors.yellow,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _debugInfo,
                  style: const TextStyle(color: Colors.white, fontSize: 9),
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
                if (_isInitialized && !_hasError) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Playing: ${_controller.value.isPlaying}\n'
                    'Position: ${_controller.value.position}\n'
                    'Duration: ${_controller.value.duration}\n'
                    'Buffered: ${_controller.value.buffered}',
                    style: const TextStyle(color: Colors.green, fontSize: 8),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 64),
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
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              _errorMessage,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _hasError = false;
                _errorMessage = '';
                _debugInfo = 'Retrying...';
              });
              _initializeVideo();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
          // const SizedBox(height: 16),
          // Text(
          //   'Loading video...',
          //   style: const TextStyle(color: Colors.white, fontSize: 14),
          // ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Video player with proper aspect ratio
        Center(
          child: AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          ),
        ),

        // Gradient overlay for better text visibility
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

        // Video progress indicator
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: VideoProgressIndicator(
            _controller,
            allowScrubbing: false,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            colors: const VideoProgressColors(
              playedColor: Colors.white,
              bufferedColor: Colors.white30,
              backgroundColor: Colors.white10,
            ),
          ),
        ),
      ],
    );
  }
}
