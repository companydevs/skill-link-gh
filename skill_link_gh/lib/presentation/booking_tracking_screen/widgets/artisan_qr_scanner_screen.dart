import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:sizer/sizer.dart';
import 'package:skill_link_gh/provider/wallet_provider.dart';
import 'package:skill_link_gh/widgets/custom_app_toast.dart';

/// Screen for the artisan to scan the client's QR code to release payment.
class ArtisanQrScannerScreen extends ConsumerStatefulWidget {
  final String expectedBookingId;
  final String artisanId;

  const ArtisanQrScannerScreen({
    super.key,
    required this.expectedBookingId,
    required this.artisanId,
  });

  @override
  ConsumerState<ArtisanQrScannerScreen> createState() =>
      _ArtisanQrScannerScreenState();
}

class _ArtisanQrScannerScreenState
    extends ConsumerState<ArtisanQrScannerScreen> {
  final MobileScannerController _ctrl = MobileScannerController();
  bool _processing = false;
  bool _scanned = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_scanned || _processing) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null) return;

    Map<String, dynamic> data;
    try {
      data = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return; // not our QR
    }

    if (data['type'] != 'payment_release') return;
    if (data['bookingId'] != widget.expectedBookingId) {
      if (mounted) {
        AppToast.show(
          context,
          message: 'QR code does not match this booking.',
          type: ToastType.error,
        );
      }
      return;
    }

    setState(() {
      _scanned = true;
      _processing = true;
    });
    await _ctrl.stop();

    final bookingId = data['bookingId'] as String;
    final amount = (data['amount'] as num).toDouble();

    final success = await ref
        .read(walletNotifierProvider.notifier)
        .releasePaymentToArtisan(
          bookingId: bookingId,
          artisanId: widget.artisanId,
          amount: amount,
        );

    if (!mounted) return;
    setState(() => _processing = false);

    if (success) {
      AppToast.show(
        context,
        message: 'Payment of GH₵ ${amount.toStringAsFixed(2)} released!',
        type: ToastType.success,
      );
      Navigator.pop(context, true);
    } else {
      AppToast.show(
        context,
        message: 'Failed to release payment. Try again.',
        type: ToastType.error,
      );
      setState(() => _scanned = false);
      await _ctrl.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Client QR Code'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _ctrl.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _ctrl, onDetect: _onDetect),
          // Overlay frame
          Center(
            child: Container(
              width: 65.w,
              height: 65.w,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          // Bottom instruction
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
              color: Colors.black.withValues(alpha: 0.7),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_processing)
                    const CircularProgressIndicator(color: Colors.white)
                  else
                    Text(
                      'Point camera at the client\'s QR code to release payment',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  SizedBox(height: 1.h),
                  Text(
                    'Booking: ${widget.expectedBookingId}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white60,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
