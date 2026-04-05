import 'package:flutter/material.dart';
import 'package:flutter_paystack_plus/flutter_paystack_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sizer/sizer.dart';
import 'package:skill_link_gh/provider/booking_provider.dart';
import 'package:skill_link_gh/widgets/custom_app_toast.dart';

import '../../widgets/custom_app_bar.dart';

class PaymentVerificationScreen extends ConsumerStatefulWidget {
  const PaymentVerificationScreen({super.key});

  @override
  ConsumerState<PaymentVerificationScreen> createState() =>
      _PaymentVerificationScreenState();
}

class _PaymentVerificationScreenState
    extends ConsumerState<PaymentVerificationScreen> {
  String? _paymentUrl; // authorization_url from Paystack via our function
  String? _bookingId;
  String? _reference;
  String? _email;
  bool _isProcessing = false;
  bool _launched = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  void _init() {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      setState(() {
        _paymentUrl = args['paymentUrl'] as String?;
        _bookingId = args['bookingId'] as String?;
        _reference = args['reference'] as String?;
        _email = args['email'] as String?;
      });
      // Auto-launch immediately
      WidgetsBinding.instance.addPostFrameCallback((_) => _launchPayment());
    }
  }

  Future<void> _launchPayment() async {
    if (_launched || _isProcessing || _paymentUrl == null) return;
    setState(() {
      _launched = true;
      _isProcessing = true;
    });

    try {
      await FlutterPaystackPlus.openPaystackPopup(
        context: context,
        // Use the authorization_url our backend already generated
        authorizationUrl: _paymentUrl!,
        customerEmail: _email ?? '',
        reference: _reference ?? '',
        amount: '', // already set server-side
        currency: 'GHS',
        callBackUrl: 'https://skill-link-gh.web.app/payment-callback',
        onSuccess: () async {
          await _verifyWithBackend();
        },
        onClosed: () {
          if (mounted) setState(() => _isProcessing = false);
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        AppToast.show(
          context,
          message: 'Payment error: $e',
          type: ToastType.error,
        );
      }
    }
  }

  Future<void> _verifyWithBackend() async {
    if (_reference == null) return;
    setState(() => _isProcessing = true);
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
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            '/booking-tracking-screen',
            arguments: {'bookingId': _bookingId, 'reference': _reference},
          );
        }
      } else {
        setState(() => _isProcessing = false);
        AppToast.show(
          context,
          message: 'Payment not confirmed yet. Tap retry.',
          type: ToastType.error,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        AppToast.show(
          context,
          message: 'Verification error: $e',
          type: ToastType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CustomAppBar(title: 'Payment', variant: AppBarVariant.standard),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(6.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isProcessing) ...[
                CircularProgressIndicator(color: theme.colorScheme.primary),
                SizedBox(height: 3.h),
                Text(
                  'Processing payment...',
                  style: theme.textTheme.titleMedium,
                ),
                SizedBox(height: 1.h),
                Text(
                  'Please wait',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ] else ...[
                Icon(
                  Icons.payment_outlined,
                  size: 64,
                  color: theme.colorScheme.primary,
                ),
                SizedBox(height: 3.h),
                Text(
                  'Complete Payment',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  'Tap below to pay securely via Paystack',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 4.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _launchPayment,
                    icon: const Icon(Icons.credit_card),
                    label: const Text('Pay Now'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 2.h),
                    ),
                  ),
                ),
                if (_launched) ...[
                  SizedBox(height: 2.h),
                  TextButton(
                    onPressed: _verifyWithBackend,
                    child: const Text('Already paid? Verify'),
                  ),
                ],
                SizedBox(height: 1.h),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
