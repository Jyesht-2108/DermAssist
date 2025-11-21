import 'dart:typed_data';
import '../core/utils/image_utils.dart';

/// Service for image preprocessing operations
/// Ensures preprocessing matches training pipeline exactly
class PreprocessingService {
  /// Singleton instance
  static final PreprocessingService _instance = PreprocessingService._internal();
  factory PreprocessingService() => _instance;
  PreprocessingService._internal();

  /// Preprocess image bytes for model input
  /// Returns normalized 224x224 image tensor or null on failure
  List<List<List<double>>>? preprocess(Uint8List imageBytes) {
    return ImageUtils.preprocessImage(imageBytes);
  }

  /// Validate preprocessed data
  bool validate(List<List<List<double>>> data) {
    if (data.length != 224) return false;
    if (data[0].length != 224) return false;
    if (data[0][0].length != 3) return false;
    return true;
  }
}
