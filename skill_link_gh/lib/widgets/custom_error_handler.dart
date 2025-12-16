import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skill_link_gh/widgets/custom_app_toast.dart';


class ErrorHandler {
  static Future<void> runWithLoader({
    required BuildContext context,
    required Future<void> Function() action,
    String? successMessage,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await action();
      _safePop(context);

      if (successMessage != null) {
        AppToast.show(
          context,
          message: successMessage,
          type: ToastType.success,
        );
      }
    } catch (e) {
      _safePop(context);

      final message = _parseError(e);

      AppToast.show(
        context,
        message: message,
        type: ToastType.error,
      );
    }
  }

  /// Prevents "Navigator.pop called on root" errors
  static void _safePop(BuildContext context) {
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  static String _parseError(dynamic e) {
    // 🔹 Cloud Functions
    if (e is FirebaseFunctionsException) {
      switch (e.code) {
        case 'already-exists':
          return 'This email is already registered. Please log in instead.';
        case 'invalid-argument':
          return e.message ?? 'Invalid information provided.';
        case 'permission-denied':
          return 'You do not have permission to perform this action.';
        case 'unavailable':
          return 'Service unavailable. Please check your internet connection.';
        default:
          return e.message ?? 'Something went wrong. Please try again.';
      }
    }

    // 🔹 Firebase Auth
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'email-already-in-use':
          return 'This email is already registered.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'weak-password':
          return 'Password is too weak. Use at least 8 characters.';
        case 'user-not-found':
          return 'No account found with this email.';
        case 'wrong-password':
          return 'Incorrect password.';
        default:
          return e.message ?? 'Authentication failed.';
      }
    }

    // 🔹 Fallback
    final msg = e.toString().replaceFirst('Exception: ', '');
    return msg.isEmpty ? 'Something went wrong.' : msg;
  }
}
