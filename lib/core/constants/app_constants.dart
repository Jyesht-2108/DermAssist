/// Application-wide constants
class AppConstants {
  // ML Model Configuration
  static const String modelPath = 'assets/models/skin_model.tflite';
  static const int modelInputSize = 224;
  static const int modelInputChannels = 3;
  
  // Inference Configuration
  static const double confidenceThreshold = 0.5;
  static const int maxInferenceTimeMs = 1000;
  
  // Image Preprocessing
  static const double normalizationMean = 127.5;
  static const double normalizationStd = 127.5;
  
  // Camera Configuration
  static const double aspectRatio = 1.0;
  
  // Private constructor to prevent instantiation
  AppConstants._();
}
