import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

enum ToastType { success, error, warning, info }

class AppToast {
  static OverlayEntry? _entry;

  static void show(
    BuildContext context, {
    required String message,
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    _entry?.remove();

    final overlay = Overlay.of(context);
    if (overlay == null) return;

    _entry = OverlayEntry(
      builder: (_) => _ToastWidget(
        message: message,
        type: type,
      ),
    );

    overlay.insert(_entry!);

    Timer(duration, () {
      _entry?.remove();
      _entry = null;
    });
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final ToastType type;

  const _ToastWidget({
    required this.message,
    required this.type,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _slide = Tween<Offset>(
      begin: const Offset(1.2, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = _toastConfig(widget.type);

    return Positioned(
      top: 5.h,
      right: 4.w,
      child: SlideTransition(
        position: _slide,
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(maxWidth: 90.w),
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.6.h),
            decoration: BoxDecoration(
              color: config.color,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(config.icon, color: Colors.white, size: 18.sp),
                SizedBox(width: 3.w),
                Flexible(
                  child: Text(
                    widget.message,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _ToastConfig _toastConfig(ToastType type) {
    switch (type) {
      case ToastType.success:
        return _ToastConfig(
          color: const Color(0xFF16A34A),
          icon: Icons.check_circle_outline,
        );
      case ToastType.error:
        return _ToastConfig(
          color: const Color(0xFFDC2626),
          icon: Icons.error_outline,
        );
      case ToastType.warning:
        return _ToastConfig(
          color: const Color(0xFFF59E0B),
          icon: Icons.warning_amber_outlined,
        );
      case ToastType.info:
      default:
        return _ToastConfig(
          color: const Color(0xFF2563EB),
          icon: Icons.info_outline,
        );
    }
  }
}

class _ToastConfig {
  final Color color;
  final IconData icon;

  _ToastConfig({
    required this.color,
    required this.icon,
  });
}
