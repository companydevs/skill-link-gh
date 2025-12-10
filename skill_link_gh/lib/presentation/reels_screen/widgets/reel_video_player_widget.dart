import 'package:flutter/material.dart';

/// Video player widget for reels
/// Displays full-screen video with auto-play functionality
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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _simulateVideoLoad();
  }

  @override
  void didUpdateWidget(ReelVideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      setState(() {
        _isLoading = true;
      });
      _simulateVideoLoad();
    }
  }

  Future<void> _simulateVideoLoad() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                )
              : Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.3),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      widget.isActive
                          ? Icons.play_circle_outline
                          : Icons.pause_circle_outline,
                      size: 80,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ),
          if (!_isLoading)
            Positioned(
              bottom: 8,
              left: 16,
              right: 16,
              child: LinearProgressIndicator(
                value: widget.isActive ? 0.6 : 0.0,
                backgroundColor: Colors.white.withValues(alpha: 0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 2,
              ),
            ),
        ],
      ),
    );
  }
}
