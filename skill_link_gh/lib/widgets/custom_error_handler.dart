// lib/widgets/custom_error_handler.dart
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sizer/sizer.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
      Navigator.of(context).pop();

      if (successMessage != null) {
        Fluttertoast.showToast(
          msg: successMessage,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.TOP_RIGHT,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 14.sp,
        );
      }
    } catch (e) {
      Navigator.of(context).pop();

      String message = _parseError(e);

      Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.TOP_RIGHT,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 14.sp,
      );
    }
  }

  static String _parseError(dynamic e) {
    if (e is FirebaseFunctionsException) {
      switch (e.code) {
        case 'already-exists':
          return 'Email is already registered';
        case 'invalid-argument':
          return e.message ?? 'Invalid data provided';
        case 'permission-denied':
          return 'You do not have permission';
        default:
          return e.message ?? 'Something went wrong';
      }
    }

    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'email-already-in-use':
          return 'Email is already registered';
        case 'invalid-email':
          return 'Invalid email address';
        case 'weak-password':
          return 'Password is too weak';
        case 'user-not-found':
          return 'No user found with this email';
        case 'wrong-password':
          return 'Incorrect password';
        default:
          return e.message ?? 'Authentication failed';
      }
    }

    return e.toString();
  }
}
