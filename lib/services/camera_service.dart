import 'dart:typed_data';
import 'package:camera/camera.dart';

/// Service for managing camera operations
class CameraService {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;

  /// Singleton instance
  static final CameraService _instance = CameraService._internal();
  factory CameraService() => _instance;
  CameraService._internal();

  /// Get camera controller
  CameraController? get controller => _controller;

  /// Check if camera is initialized
  bool get isInitialized => _isInitialized;

  /// Initialize camera
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Get available cameras
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        return false;
      }

      // Use back camera (index 0 is typically back camera)
      final camera = _cameras!.first;

      // Create controller
      _controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      // Initialize controller
      await _controller!.initialize();
      _isInitialized = true;
      return true;
    } catch (e) {
      _isInitialized = false;
      return false;
    }
  }

  /// Capture image and return as bytes
  Future<Uint8List?> captureImage() async {
    if (!_isInitialized || _controller == null) {
      return null;
    }

    try {
      final XFile image = await _controller!.takePicture();
      final Uint8List bytes = await image.readAsBytes();
      return bytes;
    } catch (e) {
      return null;
    }
  }

  /// Dispose camera resources
  Future<void> dispose() async {
    await _controller?.dispose();
    _controller = null;
    _isInitialized = false;
  }
}
