import 'package:flutter/services.dart';

/// Manages model class labels
class ModelLabels {
  static List<String>? _labels;

  /// Load labels from assets
  static Future<List<String>> loadLabels() async {
    if (_labels != null) return _labels!;

    try {
      final labelsData = await rootBundle.loadString('assets/models/labels.txt');
      _labels = labelsData.split('\n').where((label) => label.trim().isNotEmpty).toList();
      return _labels!;
    } catch (e) {
      // Return default labels if file not found
      _labels = [
        'Actinic Keratosis',
        'Basal Cell Carcinoma',
        'Benign Keratosis',
        'Dermatofibroma',
        'Melanoma',
        'Nevus (Mole)',
        'Vascular Lesion',
      ];
      return _labels!;
    }
  }

  /// Get label by index
  static String getLabel(int index) {
    if (_labels == null || index < 0 || index >= _labels!.length) {
      return 'Unknown';
    }
    return _labels![index];
  }

  /// Get risk level for a condition
  static String getRiskLevel(String label) {
    final highRisk = ['Melanoma', 'Basal Cell Carcinoma', 'Actinic Keratosis'];
    final mediumRisk = ['Dermatofibroma', 'Vascular Lesion'];
    
    if (highRisk.any((risk) => label.contains(risk))) {
      return 'High';
    } else if (mediumRisk.any((risk) => label.contains(risk))) {
      return 'Medium';
    }
    return 'Low';
  }

  /// Get color for risk level
  static int getRiskColor(String riskLevel) {
    switch (riskLevel) {
      case 'High':
        return 0xFFE53935; // Red
      case 'Medium':
        return 0xFFFB8C00; // Orange
      case 'Low':
        return 0xFF43A047; // Green
      default:
        return 0xFF757575; // Grey
    }
  }
}
