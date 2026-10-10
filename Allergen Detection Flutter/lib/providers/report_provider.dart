import 'package:flutter/material.dart';
import '../services/report_service.dart';

class ReportProvider extends ChangeNotifier {
  final ReportService _reportService = ReportService();

  bool _isLoading = false;
  String? _errorMessage;
  bool _submitSuccess = false;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get submitSuccess => _submitSuccess;

  /// Submit a report on behalf of the currently authenticated user.
  Future<void> submitReport({
    required String userId,
    required String userName,
    required String title,
    required String description,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _submitSuccess = false;
    notifyListeners();

    try {
      await _reportService.submitReport(
        userId: userId,
        userName: userName,
        title: title,
        description: description,
      );
      _submitSuccess = true;
    } catch (e) {
      _errorMessage = 'Failed to submit report. Please try again.';
      debugPrint('ReportProvider.submitReport error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Reset state — call before re-opening the submit form.
  void reset() {
    _isLoading = false;
    _errorMessage = null;
    _submitSuccess = false;
    notifyListeners();
  }
}
