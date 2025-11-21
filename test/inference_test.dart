import 'package:flutter_test/flutter_test.dart';
import 'package:derm_assist/ml/inference_service.dart';
import 'dart:typed_data';

void main() {
  test('InferenceService loads in mock mode', () async {
    final service = InferenceService();
    final loaded = await service.loadModel();
    
    expect(loaded, true);
    expect(service.isModelLoaded, true);
    expect(service.isMockMode, true);
  });

  test('InferenceService mock mode properties', () async {
    final service = InferenceService();
    await service.loadModel();
    
    expect(service.isModelLoaded, true);
    expect(service.isMockMode, true);
  });
}
