import 'dart:typed_data';
import 'package:image/image.dart' as img;
import '../constants/app_constants.dart';

/// Utility class for image preprocessing operations
class ImageUtils {
  /// Resize image to model input size (224x224)
  static img.Image resizeImage(img.Image image) {
    return img.copyResize(
      image,
      width: AppConstants.modelInputSize,
      height: AppConstants.modelInputSize,
      interpolation: img.Interpolation.linear,
    );
  }

  /// Normalize pixel values to [-1, 1] range
  /// Formula: (pixel - mean) / std
  static List<List<List<double>>> normalizeImage(img.Image image) {
    final normalized = List.generate(
      AppConstants.modelInputSize,
      (y) => List.generate(
        AppConstants.modelInputSize,
        (x) {
          final pixel = image.getPixel(x, y);
          return [
            (pixel.r - AppConstants.normalizationMean) / AppConstants.normalizationStd,
            (pixel.g - AppConstants.normalizationMean) / AppConstants.normalizationStd,
            (pixel.b - AppConstants.normalizationMean) / AppConstants.normalizationStd,
          ];
        },
      ),
    );
    return normalized;
  }

  /// Convert Uint8List bytes to img.Image
  static img.Image? bytesToImage(Uint8List bytes) {
    return img.decodeImage(bytes);
  }

  /// Full preprocessing pipeline: decode -> resize -> normalize
  static List<List<List<double>>>? preprocessImage(Uint8List imageBytes) {
    try {
      // Decode image
      final image = bytesToImage(imageBytes);
      if (image == null) return null;

      // Resize to model input size
      final resized = resizeImage(image);

      // Normalize pixel values
      final normalized = normalizeImage(resized);

      return normalized;
    } catch (e) {
      return null;
    }
  }

  // Private constructor to prevent instantiation
  ImageUtils._();
}
