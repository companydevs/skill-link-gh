import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Timer widget with resend code functionality
class ResendTimerWidget extends StatefulWidget {
  final VoidCallback onResend;
  final int initialSeconds;

  const ResendTimerWidget({
    super.key,
    required this.onResend,
    this.initialSeconds = 60,
  });

  @override
  State<ResendTimerWidget> createState() => _ResendTimerWidgetState();
}

class _ResendTimerWidgetState extends State<ResendTimerWidget>
    with SingleTickerProviderStateMixin {
  late int _remainingSeconds;
  late AnimationController _animationController;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.initialSeconds;
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.initialSeconds),
    );
    _startTimer();
  }

  void _startTimer() {
    _animationController.forward();
    Future.delayed(const Duration(seconds: 1), _updateTimer);
  }

  void _updateTimer() {
    if (!mounted) return;

    setState(() {
      _remainingSeconds--;
    });

    if (_remainingSeconds > 0) {
      Future.delayed(const Duration(seconds: 1), _updateTimer);
    } else {
      setState(() {
        _canResend = true;
      });
    }
  }

  void _handleResend() {
    if (!_canResend) return;

    HapticFeedback.mediumImpact();
    setState(() {
      _remainingSeconds = widget.initialSeconds;
      _canResend = false;
    });
    _animationController.reset();
    _startTimer();
    widget.onResend();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Didn't receive code? ",
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        _canResend
            ? InkWell(
                onTap: _handleResend,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  child: Text(
                    'Resend Code',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
            : Text(
                'Resend in ${_remainingSeconds}s',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
      ],
    );
  }
}
