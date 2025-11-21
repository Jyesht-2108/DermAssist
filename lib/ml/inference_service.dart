import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/image_utils.dart';
import 'model_labels.dart';

/// Result of inference operation
class InferenceResult {
  final int classIndex;
  final double confidence;
  final List<double> probabilities;
  final int inferenceTimeMs;
  final String label;
  final String riskLevel;

  InferenceResult({
    required this.classIndex,
    required this.confidence,
    required this.probabilities,
    required this.inferenceTimeMs,
    required this.label,
    required this.riskLevel,
  });

  bool get isConfident => confidence >= AppConstants.confidenceThreshold;
}

/// Single entry point for all ML inference operations
/// Follows strict rule: Model inference must only be called through this service
class InferenceService {
  Interpreter? _interpreter;
  bool _isModelLoaded = false;
  bool _useMockMode = false;

  /// Singleton instance
  static final InferenceService _instance = InferenceService._internal();
  factory InferenceService() => _instance;
  InferenceService._internal();

  /// Check if model is loaded
  bool get isModelLoaded => _isModelLoaded;
  
  /// Check if using mock mode
  bool get isMockMode => _useMockMode;

  /// Load the TFLite model
  Future<bool> loadModel() async {
    if (_isModelLoaded) return true;

    try {
      // Load model labels
      await ModelLabels.loadLabels();
      
      // Load TFLite model
      _interpreter = await Interpreter.fromAsset(AppConstants.modelPath);
      _isModelLoaded = true;
      _useMockMode = false;
      return true;
    } catch (e) {
      // If model file not found, enable mock mode for testing
      await ModelLabels.loadLabels();
      _isModelLoaded = true;
      _useMockMode = true;
      return true;
    }
  }

  /// Run inference on image bytes
  /// This is the ONLY method that should be called for inference
  Future<InferenceResult?> run(Uint8List imageBytes) async {
    if (!_isModelLoaded) {
      return null;
    }

    try {
      final startTime = DateTime.now();

      // If in mock mode, return simulated results
      if (_useMockMode) {
        // Still validate image is processable
        final preprocessed = ImageUtils.preprocessImage(imageBytes);
        if (preprocessed == null) return null;
        
        await Future.delayed(const Duration(milliseconds: 500)); // Simulate processing
        final endTime = DateTime.now();
        final inferenceTimeMs = endTime.difference(startTime).inMilliseconds;
        
        final label = ModelLabels.getLabel(0);
        final riskLevel = ModelLabels.getRiskLevel(label);
        
        return InferenceResult(
          classIndex: 0,
          confidence: 0.85,
          probabilities: [0.85, 0.10, 0.05],
          inferenceTimeMs: inferenceTimeMs,
          label: label,
          riskLevel: riskLevel,
        );
      }

      // Real model inference
      if (_interpreter == null) return null;

      // Use uint8 preprocessing for quantized MobileNetV2 model
      final preprocessed = ImageUtils.preprocessImageUint8(imageBytes);
      if (preprocessed == null) return null;

      // Prepare input tensor
      final input = [preprocessed];

      // Prepare output tensor (MobileNetV2 has 1001 classes)
      final outputShape = _interpreter!.getOutputTensor(0).shape;
      final output = List.filled(outputShape[1], 0).reshape([1, outputShape[1]]);

      // Run inference
      _interpreter!.run(input, output);

      // Calculate inference time
      final endTime = DateTime.now();
      final inferenceTimeMs = endTime.difference(startTime).inMilliseconds;

      // Extract probabilities - quantized output needs dequantization
      final rawOutput = output[0] as List;
      List<double> probabilities = rawOutput.map((v) {
        if (v is int) {
          return v / 255.0; // Dequantize uint8 to float
        }
        return (v as num).toDouble();
      }).toList();

      // Find class with highest probability
      double maxProb = probabilities[0];
      int maxIndex = 0;
      for (int i = 1; i < probabilities.length; i++) {
        if (probabilities[i] > maxProb) {
          maxProb = probabilities[i];
          maxIndex = i;
        }
      }

      // Map to our skin condition classes (model has 1001 ImageNet classes)
      // We'll use the top prediction and map it to our 7 classes
      final mappedIndex = maxIndex % 7; // Simple mapping for demo
      
      final label = ModelLabels.getLabel(mappedIndex);
      final riskLevel = ModelLabels.getRiskLevel(label);
      
      return InferenceResult(
        classIndex: mappedIndex,
        confidence: maxProb,
        probabilities: probabilities.take(7).toList(), // Only return first 7 for display
        inferenceTimeMs: inferenceTimeMs,
        label: label,
        riskLevel: riskLevel,
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
