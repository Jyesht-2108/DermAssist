import 'package:flutter/foundation.dart';
import '../ml/inference_service.dart';

/// Application state management
class AppState extends ChangeNotifier {
  bool _isModelLoaded = false;
  bool _isProcessing = false;
  InferenceResult? _lastResult;
  String? _errorMessage;

  bool get isModelLoaded => _isModelLoaded;
  bool get isProcessing => _isProcessing;
  InferenceResult? get lastResult => _lastResult;
  String? get errorMessage => _errorMessage;

  /// Initialize app state
  Future<void> initialize() async {
    _errorMessage = null;
    final success = await InferenceService().loadModel();
    _isModelLoaded = success;
    if (!success) {
      _errorMessage = 'Failed to load ML model';
    }
    notifyListeners();
  }

  /// Set processing state
  void setProcessing(bool processing) {
    _isProcessing = processing;
    notifyListeners();
  }

  /// Set inference result
  void setResult(InferenceResult? result) {
    _lastResult = result;
    _isProcessing = false;
    if (result == null) {
      _errorMessage = 'Inference failed';
    } else {
      _errorMessage = null;
    }
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Reset state
  void reset() {
    _lastResult = null;
    _errorMessage = null;
    _isProcessing = false;
    notifyListeners();
  }
}
