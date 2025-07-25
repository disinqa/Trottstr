import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

/// Utility class for showing toasts instead of SnackBars
class ToastUtils {
  /// Show a success toast
  static void showSuccess(String message, {String? title}) {
    toastification.show(
      title: title != null ? Text(title) : null,
      description: Text(message),
      type: ToastificationType.success,
      style: ToastificationStyle.fillColored,
      autoCloseDuration: const Duration(seconds: 3),
      showIcon: true,
    );
  }

  /// Show an error toast
  static void showError(String message, {String? title}) {
    toastification.show(
      title: title != null ? Text(title) : null,
      description: Text(message),
      type: ToastificationType.error,
      style: ToastificationStyle.fillColored,
      autoCloseDuration: const Duration(seconds: 4),
      showIcon: true,
    );
  }

  /// Show an info toast
  static void showInfo(String message, {String? title}) {
    toastification.show(
      title: title != null ? Text(title) : null,
      description: Text(message),
      type: ToastificationType.info,
      style: ToastificationStyle.fillColored,
      autoCloseDuration: const Duration(seconds: 3),
      showIcon: true,
    );
  }

  /// Show a warning toast
  static void showWarning(String message, {String? title}) {
    toastification.show(
      title: title != null ? Text(title) : null,
      description: Text(message),
      type: ToastificationType.warning,
      style: ToastificationStyle.fillColored,
      autoCloseDuration: const Duration(seconds: 3),
      showIcon: true,
    );
  }
}