import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sizer/sizer.dart';
import 'package:skill_link_gh/provider/booking_provider.dart';
import 'package:skill_link_gh/widgets/custom_app_toast.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_icon_widget.dart';

class PaymentVerificationScreen extends ConsumerStatefulWidget {
  const PaymentVerificationScreen({super.key});

  @override
  ConsumerState<PaymentVerificationScreen> createState() =>
      _PaymentVerificationScreenState();
}

class _PaymentVerificationScreenState
    extends ConsumerState<PaymentVerificationScreen> {
  bool _isVerifying = false;
  bool _paymentVerified = false;
  String? _paymentReference;
  Map<String, dynamic>? _bookingData;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadArguments();
    });
  }

  void _loadArguments() {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      setState(() {
        _bookingData = args['bookingData'];
      });
    }
  }

  Future<void> _verifyPayment() async {
    if (_paymentReference == null || _paymentReference!.isEmpty) {
      AppToast.show(
        context,
        message: 'Please enter payment reference',
        type: ToastType.error,
      );
      return;
    }

    setState(() => _isVerifying = true);

    try {
      final success = await ref
          .read(bookingNotifierProvider.notifier)
          .verifyPayment(_paymentReference!);

      if (success) {
        setState(() => _paymentVerified = true);

        AppToast.show(
          context,
          message: 'Payment verified successfully!',
          type: ToastType.success,
        );

        // Navigate to booking tracking screen after a delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pushReplacementNamed(
              context,
              '/booking-tracking-screen',
              arguments: {'paymentReference': _paymentReference},
            );
          }
        });
      } else {
        AppToast.show(
          context,
          message: 'Payment verification failed',
          type: ToastType.error,
        );
      }
    } catch (e) {
      AppToast.show(
        context,
        message: 'Error verifying payment: $e',
        type: ToastType.error,
      );
    } finally {
      setState(() => _isVerifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        variant: AppBarVariant.standard,
        title: 'Payment Verification',
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_bookingData != null) _buildBookingSummary(theme),
            SizedBox(height: 4.h),
            _buildPaymentStatus(theme),
            SizedBox(height: 4.h),
            _buildVerificationForm(theme),
            SizedBox(height: 4.h),
            _buildInstructions(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingSummary(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Booking Summary',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          _buildSummaryRow(theme, 'Service', _bookingData!['serviceTitle']),
          _buildSummaryRow(theme, 'Artisan', _bookingData!['artisanName']),
          _buildSummaryRow(theme, 'Date', _bookingData!['scheduledDate']),
          _buildSummaryRow(theme, 'Time', _bookingData!['scheduledTime']),
          _buildSummaryRow(theme, 'Total Amount', _bookingData!['totalAmount']),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentStatus(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: _paymentVerified
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: _paymentVerified
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _paymentVerified ? Icons.check : Icons.payment,
              color: _paymentVerified
                  ? Colors.white
                  : theme.colorScheme.onSurfaceVariant,
              size: 24,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _paymentVerified
                      ? 'Payment Verified'
                      : 'Awaiting Payment Verification',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _paymentVerified
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  _paymentVerified
                      ? 'Your booking has been confirmed'
                      : 'Please verify your payment to confirm booking',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _paymentVerified
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationForm(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Reference',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          TextFormField(
            onChanged: (value) => _paymentReference = value,
            decoration: InputDecoration(
              hintText: 'Enter payment reference from Paystack',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.receipt_long),
            ),
          ),
          SizedBox(height: 3.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isVerifying || _paymentVerified
                  ? null
                  : _verifyPayment,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 2.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isVerifying
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      _paymentVerified ? 'Payment Verified' : 'Verify Payment',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              SizedBox(width: 2.w),
              Text(
                'How to find your payment reference',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.5.h),
          _buildInstructionStep(
            theme,
            '1',
            'Check your email for payment confirmation',
          ),
          _buildInstructionStep(
            theme,
            '2',
            'Look for the transaction reference in SMS',
          ),
          _buildInstructionStep(
            theme,
            '3',
            'Copy the reference and paste it above',
          ),
          _buildInstructionStep(
            theme,
            '4',
            'Click "Verify Payment" to confirm',
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(
    ThemeData theme,
    String step,
    String instruction,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                step,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Text(
              instruction,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
