// Optimized video player with caching, preloading, and better performance
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';

/// Global video controller cache for preloading and reuse
class VideoControllerCache {
  static final VideoControllerCache _instance =
      VideoControllerCache._internal();
  factory VideoControllerCache() => _instance;
  VideoControllerCache._internal();

  final Map<String, VideoPlayerController> _cache = {};
  final Map<String, DateTime> _lastAccessed = {};
  static const int maxCacheSize = 5; // Keep 5 videos in memory
  static const Duration cacheExpiry = Duration(minutes: 10);

  VideoPlayerController? get(String url) {
    _cleanExpiredCache();
    if (_cache.containsKey(url)) {
      _lastAccessed[url] = DateTime.now();
      return _cache[url];
    }
    return null;
  }

  Future<VideoPlayerController> getOrCreate(
    String url, {
    Map<String, String>? headers,
  }) async {
    final cached = get(url);
    if (cached != null && cached.value.isInitialized) {
      return cached;
    }

    // Remove from cache if exists but not initialized
    if (cached != null) {
      await remove(url);
    }

    // Create new controller
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(url),
      videoPlayerOptions: VideoPlayerOptions(
        mixWithOthers: true,
        allowBackgroundPlayback: false,
      ),
      httpHeaders: headers ?? _defaultHeaders,
    );

    await controller.initialize();
    await controller.setLooping(true);

    _cache[url] = controller;
    _lastAccessed[url] = DateTime.now();

    // Enforce cache size limit
    _enforceCacheLimit();

    return controller;
  }

  Future<void> preload(String url, {Map<String, String>? headers}) async {
    if (_cache.containsKey(url)) return;

    try {
      await getOrCreate(url, headers: headers);
    } catch (e) {
      // Preload failure is non-critical
      debugPrint('Preload failed for $url: $e');
    }
  }

  Future<void> remove(String url) async {
    final controller = _cache.remove(url);
    _lastAccessed.remove(url);
    if (controller != null) {
      await controller.dispose();
    }
  }

  void _cleanExpiredCache() {
    final now = DateTime.now();
    final expired = <String>[];

    _lastAccessed.forEach((url, lastAccess) {
      if (now.difference(lastAccess) > cacheExpiry) {
        expired.add(url);
      }
    });

    for (final url in expired) {
      remove(url);
    }
  }

  void _enforceCacheLimit() {
    if (_cache.length <= maxCacheSize) return;

    // Remove least recently accessed
    final sorted = _lastAccessed.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    final toRemove = sorted.take(_cache.length - maxCacheSize);
    for (final entry in toRemove) {
      remove(entry.key);
    }
  }

  Future<void> clear() async {
    final urls = _cache.keys.toList();
    for (final url in urls) {
      await remove(url);
    }
  }

  static Map<String, String> get _defaultHeaders => {
    'Cache-Control': 'max-age=7200',
    'User-Agent': 'SkillLink-Mobile-App/1.0',
    'Accept': 'video/*',
  };
}

class OptimizedReelVideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final bool isActive;
  final bool isMuted;
  final List<String>? preloadUrls; // URLs to preload
  final VoidCallback? onVideoError;

  const OptimizedReelVideoPlayerWidget({
    super.key,
    required this.videoUrl,
    required this.isActive,
    required this.isMuted,
    this.preloadUrls,
    this.onVideoError,
  });

  @override
  State<OptimizedReelVideoPlayerWidget> createState() =>
      _OptimizedReelVideoPlayerWidgetState();
}

class _OptimizedReelVideoPlayerWidgetState
    extends State<OptimizedReelVideoPlayerWidget> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isLoading = true;
  int _retryCount = 0;
  static const int _maxRetries = 2;
  static const Duration _initTimeout = Duration(seconds: 15);

  final _cache = VideoControllerCache();
  Timer? _preloadTimer;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    _schedulePreloading();
  }

  void _schedulePreloading() {
    // Preload next videos after a short delay
    _preloadTimer = Timer(const Duration(milliseconds: 500), () {
      if (widget.preloadUrls != null && widget.preloadUrls!.isNotEmpty) {
        for (final url in widget.preloadUrls!) {
          _cache.preload(url);
        }
      }
    });
  }

  Future<void> _initializeVideo() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      if (widget.videoUrl.isEmpty) {
        throw Exception('Video URL is empty');
      }

      final uri = Uri.parse(widget.videoUrl);
      if (!uri.hasScheme || (!uri.isScheme('http') && !uri.isScheme('https'))) {
        throw Exception('Invalid URL scheme');
      }

      // Try to get from cache or create new
      _controller = await _cache
          .getOrCreate(widget.videoUrl)
          .timeout(
            _initTimeout,
            onTimeout: () {
              throw TimeoutException(
                'Video initialization timeout after ${_initTimeout.inSeconds}s',
              );
            },
          );

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _hasError = false;
          _isLoading = false;
          _retryCount = 0;
        });

        // Configure playback
        _controller!.setVolume(widget.isMuted ? 0.0 : 1.0);

        if (widget.isActive) {
          await _controller!.play();
        }
      }
    } catch (e) {
      if (mounted) {
        final shouldRetry = _retryCount < _maxRetries && _shouldRetryError(e);

        setState(() {
          _hasError = true;
          _isLoading = false;
          _errorMessage = shouldRetry
              ? 'Loading... (${_retryCount + 1}/$_maxRetries)'
              : _getErrorMessage(e);
          _isInitialized = false;
        });

        if (shouldRetry) {
          _retryCount++;
          await Future.delayed(Duration(seconds: _retryCount));
          if (mounted) {
            _initializeVideo();
          }
        } else if (_is404Error(e) && widget.onVideoError != null) {
          widget.onVideoError!();
        }
      }
    }
  }

  bool _is404Error(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('404') || errorString.contains('not found');
  }

  bool _shouldRetryError(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('404') ||
        errorString.contains('403') ||
        errorString.contains('401')) {
      return false;
    }

    return errorString.contains('timeout') ||
        errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('failed to load');
  }

  String _getErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('404')) {
      return 'Video not found';
    } else if (errorString.contains('403')) {
      return 'Access denied';
    } else if (errorString.contains('timeout')) {
      return 'Loading timeout. Check your connection.';
    } else if (errorString.contains('network')) {
      return 'Network error. Check your internet.';
    } else {
      return 'Failed to load video';
    }
  }

  @override
  void didUpdateWidget(OptimizedReelVideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle URL changes
    if (oldWidget.videoUrl != widget.videoUrl) {
      _controller = null;
      _isInitialized = false;
      _hasError = false;
      _retryCount = 0;
      _initializeVideo();
      _schedulePreloading();
      return;
    }

    // Handle play/pause
    if (oldWidget.isActive != widget.isActive &&
        _isInitialized &&
        !_hasError &&
        _controller != null) {
      if (widget.isActive) {
        _controller!.play();
      } else {
        _controller!.pause();
      }
    }

    // Handle mute/unmute
    if (oldWidget.isMuted != widget.isMuted &&
        _isInitialized &&
        !_hasError &&
        _controller != null) {
      _controller!.setVolume(widget.isMuted ? 0.0 : 1.0);
    }

    // Handle preload list changes
    if (oldWidget.preloadUrls != widget.preloadUrls) {
      _schedulePreloading();
    }
  }

  @override
  void dispose() {
    _preloadTimer?.cancel();
    // Don't dispose controller - it's managed by cache
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Error state
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
              if (_retryCount >= _maxRetries)
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

    // Loading state
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
              if (_retryCount > 0) ...[
                const SizedBox(height: 16),
                Text(
                  'Retrying... ($_retryCount/$_maxRetries)',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ],
          ),
        ),
      );
    }

    // Video player
    return Stack(
      fit: StackFit.expand,
      children: [
        Center(
          child: AspectRatio(
            aspectRatio: _controller!.value.aspectRatio,
            child: VideoPlayer(_controller!),
          ),
        ),

        // Gradient overlay
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

        // Buffering indicator
        if (_controller!.value.isBuffering)
          Container(
            color: Colors.black26,
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
          ),

        // Progress indicator
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: VideoProgressIndicator(
            _controller!,
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
