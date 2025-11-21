import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/image_utils.dart';

/// Result of inference operation
class InferenceResult {
  final int classIndex;
  final double confidence;
  final List<double> probabilities;
  final int inferenceTimeMs;

  InferenceResult({
    required this.classIndex,
    required this.confidence,
    required this.probabilities,
    required this.inferenceTimeMs,
  });

  bool get isConfident => confidence >= AppConstants.confidenceThreshold;
}

/// Single entry point for all ML inference operations
/// Follows strict rule: Model inference must only be called through this service
class InferenceService {
  Interpreter? _interpreter;
  bool _isModelLoaded = false;

  /// Singleton instance
  static final InferenceService _instance = InferenceService._internal();
  factory InferenceService() => _instance;
  InferenceService._internal();

  /// Check if model is loaded
  bool get isModelLoaded => _isModelLoaded;

  /// Load the TFLite model
  Future<bool> loadModel() async {
    if (_isModelLoaded) return true;

    try {
      _interpreter = await Interpreter.fromAsset(AppConstants.modelPath);
      _isModelLoaded = true;
      return true;
    } catch (e) {
      _isModelLoaded = false;
      return false;
    }
  }

  /// Run inference on image bytes
  /// This is the ONLY method that should be called for inference
  Future<InferenceResult?> run(Uint8List imageBytes) async {
    if (!_isModelLoaded || _interpreter == null) {
      return null;
    }

    try {
      final startTime = DateTime.now();

      // Preprocess image
      final preprocessed = ImageUtils.preprocessImage(imageBytes);
      if (preprocessed == null) return null;

      // Prepare input tensor
      final input = [preprocessed];

      // Prepare output tensor
      final outputShape = _interpreter!.getOutputTensor(0).shape;
      final output = List.filled(outputShape[1], 0.0).reshape([1, outputShape[1]]);

      // Run inference
      _interpreter!.run(input, output);

      // Calculate inference time
      final endTime = DateTime.now();
      final inferenceTimeMs = endTime.difference(startTime).inMilliseconds;

      // Extract probabilities
      final probabilities = List<double>.from(output[0]);

      // Find class with highest probability
      double maxProb = probabilities[0];
      int maxIndex = 0;
      for (int i = 1; i < probabilities.length; i++) {
        if (probabilities[i] > maxProb) {
          maxProb = probabilities[i];
          maxIndex = i;
        }
      }

      return InferenceResult(
        classIndex: maxIndex,
        confidence: maxProb,
        probabilities: probabilities,
        inferenceTimeMs: inferenceTimeMs,
      );
    } catch (e) {
      return null;
    }
  }

  /// Dispose resources
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isModelLoaded = false;
  }
}
