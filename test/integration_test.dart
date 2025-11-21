import 'package:flutter_test/flutter_test.dart';
import 'package:derm_assist/ml/inference_service.dart';
import 'package:derm_assist/ml/model_labels.dart';

void main() {
  group('DermAssist Integration Tests', () {
    test('Model labels load correctly', () async {
      final labels = await ModelLabels.loadLabels();
      
      expect(labels, isNotEmpty);
      expect(labels.length, 7);
      expect(labels[0], 'Actinic Keratosis');
      expect(labels[4], 'Melanoma');
    });

    test('Risk levels are assigned correctly', () {
      expect(ModelLabels.getRiskLevel('Melanoma'), 'High');
      expect(ModelLabels.getRiskLevel('Basal Cell Carcinoma'), 'High');
      expect(ModelLabels.getRiskLevel('Dermatofibroma'), 'Medium');
      expect(ModelLabels.getRiskLevel('Benign Keratosis'), 'Low');
    });

    test('Risk colors are assigned correctly', () {
      expect(ModelLabels.getRiskColor('High'), 0xFFE53935);
      expect(ModelLabels.getRiskColor('Medium'), 0xFFFB8C00);
      expect(ModelLabels.getRiskColor('Low'), 0xFF43A047);
    });

    test('InferenceService initializes', () async {
      final service = InferenceService();
      final loaded = await service.loadModel();
      
      expect(loaded, true);
      expect(service.isModelLoaded, true);
    });

    test('Label retrieval works', () {
      final label = ModelLabels.getLabel(0);
      expect(label, isNotEmpty);
      
      final invalidLabel = ModelLabels.getLabel(999);
      expect(invalidLabel, 'Unknown');
    });
  });
}
