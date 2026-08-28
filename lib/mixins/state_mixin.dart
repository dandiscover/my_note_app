// lib/mixins/state_mixin.dart
// 统一状态管理混入

import 'package:flutter/material.dart';
import '../utils/snackbar_utils.dart';

mixin StateMixin<T extends StatefulWidget> on State<T> {
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  set isLoading(bool value) {
    if (mounted) {
      setState(() {
        _isLoading = value;
      });
    }
  }

  void showSuccess(String message) {
    if (mounted) SnackBarUtils.showSuccess(context, message);
  }

  void showError(String message) {
    if (mounted) SnackBarUtils.showError(context, message);
  }

  void showInfo(String message) {
    if (mounted) SnackBarUtils.showInfo(context, message);
  }

  void showWarning(String message) {
    if (mounted) SnackBarUtils.showWarning(context, message);
  }

  /// 执行异步操作，自动管理加载状态
  Future<T?> runAsync<T>(Future<T> Function() action) async {
    isLoading = true;
    try {
      final result = await action();
      return result;
    } catch (e) {
      showError('操作失败: $e');
      return null;
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 执行异步操作，带成功回调
  Future<bool> runAsyncWithSuccess(
    Future<void> Function() action, {
    String? successMessage,
  }) async {
    isLoading = true;
    try {
      await action();
      if (successMessage != null) showSuccess(successMessage);
      return true;
    } catch (e) {
      showError('操作失败: $e');
      return false;
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}