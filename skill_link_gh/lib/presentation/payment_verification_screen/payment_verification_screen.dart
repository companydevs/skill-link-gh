import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sizer/sizer.dart';
import 'package:skill_link_gh/provider/booking_provider.dart';
import 'package:skill_link_gh/widgets/custom_app_toast.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../widgets/custom_app_bar.dart';

class PaymentVerificationScreen extends ConsumerStatefulWidget {
  const PaymentVerificationScreen({super.key});

  @override
  ConsumerState<PaymentVerificationScreen> createState() =>
      _PaymentVerificationScreenState();
}

class _PaymentVerificationScreenState
    extends ConsumerState<PaymentVerificationScreen>
    with WidgetsBindingObserver {
  String? _paymentUrl;
  String? _bookingId;
  String? _reference;
  bool _isVerifying = false;
  bool _urlOpened = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Called when app comes back to foreground (after Paystack browser)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _urlOpened && !_isVerifying) {
      _verifyPayment();
    }
  }

  void _init() {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      setState(() {
        _paymentUrl = args['paymentUrl'] as String?;
        _bookingId = args['bookingId'] as String?;
        _reference = args['reference'] as String?;
      });
      // Auto-open Paystack checkout
      if (_paymentUrl != null) {
        _openPaystack();
      }
    }
  }

  Future<void> _openPaystack() async {
    if (_paymentUrl == null) return;
    final uri = Uri.parse(_paymentUrl!);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      setState(() => _urlOpened = true);
    } else {
      if (mounted) {
        AppToast.show(
          context,
          message: 'Could not open payment page',
          type: ToastType.error,
        );
      }
    }
  }

  Future<void> _verifyPayment() async {
    if (_reference == null || _isVerifying) return;
    setState(() => _isVerifying = true);
    try {
      final success = await ref
          .read(bookingNotifierProvider.notifier)
          .verifyPayment(_reference!);

      if (!mounted) return;

      if (success) {
        AppToast.show(
          context,
          message: 'Payment confirmed! Booking is active.',
          type: ToastType.success,
        );
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            '/booking-tracking-screen',
            arguments: {'bookingId': _bookingId, 'reference': _reference},
          );
        }
      } else {
        AppToast.show(
          context,
          message: 'Payment not confirmed yet. Try again.',
          type: ToastType.error,
        );
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context,
          message: 'Verification error: $e',
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Complete Payment',
        variant: AppBarVariant.standard,
      ),
      body: Padding(
        padding: EdgeInsets.all(6.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.payment,
                size: 40,
                color: theme.colorScheme.primary,
              ),
            ),
            SizedBox(height: 3.h),

            Text(
              'Complete Your Payment',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 1.h),
            Text(
              _urlOpened
                  ? 'Once you complete payment in the browser, come back here and tap "I\'ve Paid".'
                  : 'Tap below to open the Paystack payment page.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),

            // Open Paystack button
            if (!_urlOpened) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _openPaystack,
                  icon: const Icon(Icons.open_in_browser),
                  label: const Text('Open Payment Page'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 2.h),
                  ),
                ),
              ),
              SizedBox(height: 2.h),
            ],

            // I've paid button
            if (_urlOpened) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isVerifying ? null : _verifyPayment,
                  icon: _isVerifying
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: Text(_isVerifying ? 'Verifying...' : "I've Paid"),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 2.h),
                  ),
                ),
              ),
              SizedBox(height: 2.h),
              TextButton.icon(
                onPressed: _openPaystack,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Reopen payment page'),
              ),
            ],

            SizedBox(height: 2.h),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
