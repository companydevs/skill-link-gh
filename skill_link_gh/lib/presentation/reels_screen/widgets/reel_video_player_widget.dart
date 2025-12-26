// widgets/reel_video_player_widget.dart
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class ReelVideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final bool isActive;
  final bool isMuted;
  final VoidCallback? onVideoError; // Callback for when video fails to load

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
  int _retryCount = 0;
  static const int _maxRetries = 2; // Reduced retries for faster failure

  // Performance optimization: preload and dispose management
  bool _isDisposed = false;

  // Lightweight timeout for better UX
  static const Duration _initTimeout = Duration(
    seconds: 20,
  ); // Reduced from 30s

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
      // Validate URL first
      if (widget.videoUrl.isEmpty) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Video URL is empty';
          _isLoading = false;
        });
        return;
      }

      // Validate URL format
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

      print('🎬 Initializing video: ${widget.videoUrl.substring(0, 60)}...');

      // Create controller with proper URI parsing and optimized settings
      _controller = VideoPlayerController.networkUrl(
        parsedUri,
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: true,
          allowBackgroundPlayback: false,
        ),
        httpHeaders: {
          'Cache-Control': 'max-age=7200', // Extended cache for performance
          'User-Agent': 'SkillLink-Mobile-App/1.0',
          'Accept': 'video/*',
        },
      );

      // Add listener for buffering status
      _controller.addListener(_videoPlayerListener);

      // Initialize with reduced timeout for faster feedback
      await _controller.initialize().timeout(
        _initTimeout,
        onTimeout: () {
          throw Exception(
            'Video initialization timeout after ${_initTimeout.inSeconds} seconds. Check your connection.',
          );
        },
      );

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _hasError = false;
          _isLoading = false;
          _retryCount = 0; // Reset retry count on success
        });

        print('✅ Video initialized successfully');

        // Configure video settings
        _controller.setLooping(true);
        _controller.setVolume(widget.isMuted ? 0.0 : 1.0);

        // Auto-play if active
        if (widget.isActive) {
          _controller.play();
        }
      }
    } catch (e) {
      if (mounted) {
        print('❌ Video initialization error (attempt ${_retryCount + 1}): $e');

        // Determine if we should retry based on error type
        bool shouldRetry = _retryCount < _maxRetries && _shouldRetryError(e);

        setState(() {
          _hasError = true;
          _isLoading = false;
          _errorMessage = shouldRetry
              ? 'Loading video... (attempt ${_retryCount + 1}/$_maxRetries)'
              : _getErrorMessage(e);
          _isInitialized = false;
        });

        // Auto-retry for network-related errors with shorter delay
        if (shouldRetry) {
          _retryCount++;
          await Future.delayed(Duration(seconds: _retryCount)); // Faster retry
          if (mounted && !_isDisposed) {
            _initializeVideo();
          }
        } else if (_is404Error(e) && widget.onVideoError != null) {
          // Notify parent component about 404 error so it can refresh the URL
          widget.onVideoError!();
        }
      }
    }
  }

  void _videoPlayerListener() {
    if (!mounted) return;

    // Handle buffering states
    if (_controller.value.isBuffering && _isInitialized) {
      // Video is buffering - this is normal for large files
      print('📡 Video buffering...');
    }
  }

  bool _is404Error(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('404') || errorString.contains('not found');
  }

  bool _shouldRetryError(dynamic error) {
    final errorString = error.toString().toLowerCase();

    // Don't retry 404 errors - file doesn't exist
    if (errorString.contains('404') || errorString.contains('not found')) {
      return false;
    }

    // Don't retry 403 errors - permission denied
    if (errorString.contains('403') || errorString.contains('forbidden')) {
      return false;
    }

    // Don't retry 401 errors - unauthorized
    if (errorString.contains('401') || errorString.contains('unauthorized')) {
      return false;
    }

    // Retry these errors
    return errorString.contains('timeout') ||
        errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('failed to load') ||
        errorString.contains('source error');
  }

  String _getErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('404') || errorString.contains('not found')) {
      return 'Video file not found. The video may have been deleted or the link has expired.';
    } else if (errorString.contains('403') ||
        errorString.contains('forbidden')) {
      return 'Access denied. You don\'t have permission to view this video.';
    } else if (errorString.contains('401') ||
        errorString.contains('unauthorized')) {
      return 'Authentication required. Please sign in again.';
    } else if (errorString.contains('timeout')) {
      return 'Video is taking longer to load. This may be due to file size or network speed.';
    } else if (errorString.contains('network') ||
        errorString.contains('connection')) {
      return 'Network connection issue. Please check your internet connection.';
    } else if (errorString.contains('format') ||
        errorString.contains('codec')) {
      return 'Video format not supported.';
    } else if (errorString.contains('source error')) {
      return 'Video source error. The file may be corrupted or inaccessible.';
    } else {
      return 'Failed to load video: ${error.toString()}';
    }
  }

  @override
  void didUpdateWidget(ReelVideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle URL changes
    if (oldWidget.videoUrl != widget.videoUrl) {
      _controller.removeListener(_videoPlayerListener);
      _controller.dispose();
      _isInitialized = false;
      _hasError = false;
      _retryCount = 0;
      _initializeVideo();
      return;
    }

    // Handle play/pause state changes
    if (oldWidget.isActive != widget.isActive && _isInitialized && !_hasError) {
      if (widget.isActive) {
        _controller.play();
      } else {
        _controller.pause();
      }
    }

    // Handle mute/unmute changes
    if (oldWidget.isMuted != widget.isMuted && _isInitialized && !_hasError) {
      _controller.setVolume(widget.isMuted ? 0.0 : 1.0);
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    if (_isInitialized) {
      _controller.removeListener(_videoPlayerListener);
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show error state
    if (_hasError && !_isLoading) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _retryCount >= _maxRetries
                    ? Icons.error_outline
                    : Icons.refresh,
                color: Colors.white70,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                _retryCount >= _maxRetries
                    ? 'Video failed to load'
                    : 'Loading video...',
                style: const TextStyle(
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
              if (_retryCount >= _maxRetries) ...[
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    _retryCount = 0;
                    setState(() {
                      _hasError = false;
                      _errorMessage = '';
                    });
                    _initializeVideo();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    // Show loading state with better UX for large files
    if (!_isInitialized || _isLoading) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
              const SizedBox(height: 16),
              Text(
                _retryCount > 0
                    ? 'Retrying... ($_retryCount/$_maxRetries)'
                    : 'Loading video...',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              if (_retryCount == 0) ...[
                const SizedBox(height: 8),
                const Text(
                  'Large videos may take longer to load',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      );
    }

    // Show video player
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

        // Buffering indicator overlay
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

        // Video progress indicator
        if (_controller.value.isInitialized)
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
