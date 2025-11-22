import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Service for handling gyroscope-driven motion effects
class MotionService {
  static final MotionService _instance = MotionService._internal();
  factory MotionService() => _instance;
  MotionService._internal();

  StreamSubscription<GyroscopeEvent>? _gyroSubscription;
  final ValueNotifier<MotionData> _motionNotifier = ValueNotifier(MotionData.zero());
  
  // Smoothing and filtering
  double _smoothedX = 0.0;
  double _smoothedY = 0.0;
  double _smoothedZ = 0.0;
  static const double _smoothingFactor = 0.15; // Lower = smoother
  static const double _maxTilt = 0.3; // Maximum tilt angle in radians
  
  bool _isActive = false;

  ValueNotifier<MotionData> get motionNotifier => _motionNotifier;
  bool get isActive => _isActive;

  /// Start listening to gyroscope
  void start() {
    if (_isActive) return;
    
    _isActive = true;
    _gyroSubscription = gyroscopeEventStream(
      samplingPeriod: const Duration(milliseconds: 16), // ~60 FPS
    ).listen((GyroscopeEvent event) {
      _processGyroData(event);
    });
  }

  /// Stop listening to gyroscope
  void stop() {
    _isActive = false;
    _gyroSubscription?.cancel();
    _gyroSubscription = null;
    _resetSmoothing();
  }

  /// Process gyroscope data with smoothing
  void _processGyroData(GyroscopeEvent event) {
    // Apply exponential smoothing
    _smoothedX = _smoothedX * (1 - _smoothingFactor) + event.x * _smoothingFactor;
    _smoothedY = _smoothedY * (1 - _smoothingFactor) + event.y * _smoothingFactor;
    _smoothedZ = _smoothedZ * (1 - _smoothingFactor) + event.z * _smoothingFactor;

    // Clamp values to prevent extreme movements
    final clampedX = _smoothedX.clamp(-_maxTilt, _maxTilt);
    final clampedY = _smoothedY.clamp(-_maxTilt, _maxTilt);
    final clampedZ = _smoothedZ.clamp(-_maxTilt, _maxTilt);

    // Update motion data
    _motionNotifier.value = MotionData(
      x: clampedX,
      y: clampedY,
      z: clampedZ,
      timestamp: DateTime.now(),
    );
  }

  /// Reset smoothing values
  void _resetSmoothing() {
    _smoothedX = 0.0;
    _smoothedY = 0.0;
    _smoothedZ = 0.0;
    _motionNotifier.value = MotionData.zero();
  }

  /// Dispose resources
  void dispose() {
    stop();
    _motionNotifier.dispose();
  }
}

/// Motion data from gyroscope
class MotionData {
  final double x;
  final double y;
  final double z;
  final DateTime timestamp;

  const MotionData({
    required this.x,
    required this.y,
    required this.z,
    required this.timestamp,
  });

  factory MotionData.zero() {
    return MotionData(
      x: 0.0,
      y: 0.0,
      z: 0.0,
      timestamp: DateTime.now(),
    );
  }

  /// Get parallax offset for UI elements
  /// Multiplier controls the intensity of the effect
  Offset getParallaxOffset(double multiplier) {
    // Convert gyro rotation to screen offset
    // Invert Y for natural feel
    return Offset(
      y * multiplier * 20, // Scale factor for visible movement
      -x * multiplier * 20,
    );
  }

  /// Get blur amount based on motion intensity
  /// Returns value between 0 and maxBlur
  double getBlurAmount(double maxBlur) {
    final intensity = math.sqrt(x * x + y * y + z * z);
    final normalized = (intensity / 0.5).clamp(0.0, 1.0);
    return normalized * maxBlur;
  }

  /// Get scale factor for depth effect
  double getScaleFactor(double baseScale, double maxScale) {
    final intensity = math.sqrt(x * x + y * y);
    final normalized = (intensity / 0.3).clamp(0.0, 1.0);
    return baseScale + (normalized * (maxScale - baseScale));
  }
}
