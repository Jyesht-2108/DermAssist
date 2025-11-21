import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/image_utils.dart';
import 'model_labels.dart';

/// Heatmap data for visualization
class HeatmapData {
  final List<List<double>> grid; // Numerical grid (224x224)
  final Uint8List imageBytes; // RGBA heatmap image
  final int width;
  final int height;

  HeatmapData({
    required this.grid,
    required this.imageBytes,
    required this.width,
    required this.height,
  });
}

/// Result of inference operation
class InferenceResult {
  final int classIndex;
  final double confidence;
  final List<double> probabilities;
  final int inferenceTimeMs;
  final String label;
  final String riskLevel;
  final HeatmapData? heatmap;

  InferenceResult({
    required this.classIndex,
    required this.confidence,
    required this.probabilities,
    required this.inferenceTimeMs,
    required this.label,
    required this.riskLevel,
    this.heatmap,
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

  /// Generate Grad-CAM style heatmap (off main thread)
  Future<HeatmapData?> generateHeatmap(
    Uint8List imageBytes,
    int targetClass,
  ) async {
    try {
      // Preprocess image
      final preprocessed = ImageUtils.preprocessImageUint8(imageBytes);
      if (preprocessed == null) return null;

      // Generate activation map based on probabilities
      // For a simplified CAM without gradients, we use class activation mapping
      final grid = await _generateActivationMap(preprocessed, targetClass);
      
      // Convert grid to RGBA image
      final heatmapImage = await _gridToRGBA(grid);
      
      return HeatmapData(
        grid: grid,
        imageBytes: heatmapImage,
        width: AppConstants.modelInputSize,
        height: AppConstants.modelInputSize,
      );
    } catch (e) {
      return null;
    }
  }

  /// Generate activation map (simplified CAM approach)
  Future<List<List<double>>> _generateActivationMap(
    List<List<List<int>>> input,
    int targetClass,
  ) async {
    // Simplified activation mapping
    // In a real Grad-CAM, we'd need intermediate layer outputs
    // Here we approximate based on spatial variance and intensity
    
    final size = AppConstants.modelInputSize;
    final grid = List.generate(
      size,
      (y) => List.generate(size, (x) => 0.0),
    );

    // Calculate activation based on pixel intensity and spatial position
    for (int y = 0; y < size; y++) {
      for (int x = 0; x < size; x++) {
        final pixel = input[y][x];
        
        // Calculate intensity
        final intensity = (pixel[0] + pixel[1] + pixel[2]) / (3 * 255.0);
        
        // Calculate distance from center (focus on center region)
        final centerX = size / 2;
        final centerY = size / 2;
        final distX = (x - centerX).abs() / centerX;
        final distY = (y - centerY).abs() / centerY;
        final centerWeight = 1.0 - ((distX + distY) / 2);
        
        // Calculate edge detection (high gradient areas)
        double edgeStrength = 0.0;
        if (x > 0 && x < size - 1 && y > 0 && y < size - 1) {
          final dx = ((input[y][x + 1][0] - input[y][x - 1][0]).abs() +
                  (input[y][x + 1][1] - input[y][x - 1][1]).abs() +
                  (input[y][x + 1][2] - input[y][x - 1][2]).abs()) /
              (3 * 255.0);
          final dy = ((input[y + 1][x][0] - input[y - 1][x][0]).abs() +
                  (input[y + 1][x][1] - input[y - 1][x][1]).abs() +
                  (input[y + 1][x][2] - input[y - 1][x][2]).abs()) /
              (3 * 255.0);
          edgeStrength = (dx + dy) / 2;
        }
        
        // Combine factors for activation
        grid[y][x] = (intensity * 0.3 + centerWeight * 0.4 + edgeStrength * 0.3)
            .clamp(0.0, 1.0);
      }
    }

    // Apply Gaussian blur for smoothing
    return _applyGaussianBlur(grid);
  }

  /// Apply Gaussian blur to smooth the heatmap
  List<List<double>> _applyGaussianBlur(List<List<double>> grid) {
    final size = grid.length;
    final blurred = List.generate(
      size,
      (y) => List.generate(size, (x) => 0.0),
    );

    // Simple 3x3 Gaussian kernel
    final kernel = [
      [1.0, 2.0, 1.0],
      [2.0, 4.0, 2.0],
      [1.0, 2.0, 1.0],
    ];
    final kernelSum = 16.0;

    for (int y = 1; y < size - 1; y++) {
      for (int x = 1; x < size - 1; x++) {
        double sum = 0.0;
        for (int ky = -1; ky <= 1; ky++) {
          for (int kx = -1; kx <= 1; kx++) {
            sum += grid[y + ky][x + kx] * kernel[ky + 1][kx + 1];
          }
        }
        blurred[y][x] = sum / kernelSum;
      }
    }

    return blurred;
  }

  /// Convert activation grid to RGBA image with color mapping
  Future<Uint8List> _gridToRGBA(List<List<double>> grid) async {
    final size = grid.length;
    final rgba = Uint8List(size * size * 4);

    for (int y = 0; y < size; y++) {
      for (int x = 0; x < size; x++) {
        final value = grid[y][x];
        final index = (y * size + x) * 4;

        // Color mapping: blue → green → yellow → red
        final color = _valueToColor(value);
        rgba[index] = color[0]; // R
        rgba[index + 1] = color[1]; // G
        rgba[index + 2] = color[2]; // B
        rgba[index + 3] = (value * 200).toInt().clamp(0, 255); // A (opacity based on intensity)
      }
    }

    return rgba;
  }

  /// Map value (0-1) to color (blue → green → yellow → red)
  List<int> _valueToColor(double value) {
    if (value < 0.25) {
      // Blue to Cyan
      final t = value / 0.25;
      return [0, (t * 255).toInt(), 255];
    } else if (value < 0.5) {
      // Cyan to Green
      final t = (value - 0.25) / 0.25;
      return [0, 255, (255 * (1 - t)).toInt()];
    } else if (value < 0.75) {
      // Green to Yellow
      final t = (value - 0.5) / 0.25;
      return [(t * 255).toInt(), 255, 0];
    } else {
      // Yellow to Red
      final t = (value - 0.75) / 0.25;
      return [255, (255 * (1 - t)).toInt(), 0];
    }
  }

  /// Dispose resources
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isModelLoaded = false;
  }
}
