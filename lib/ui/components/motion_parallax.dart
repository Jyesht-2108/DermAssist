import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/motion_service.dart';
import '../../state/app_state.dart';

/// Widget that applies parallax motion effect to its child
class MotionParallax extends StatefulWidget {
  final Widget child;
  final double intensity;
  final bool enableBlur;
  final double maxBlur;

  const MotionParallax({
    super.key,
    required this.child,
    this.intensity = 1.0,
    this.enableBlur = false,
    this.maxBlur = 3.0,
  });

  @override
  State<MotionParallax> createState() => _MotionParallaxState();
}

class _MotionParallaxState extends State<MotionParallax> {
  final MotionService _motionService = MotionService();

  @override
  void initState() {
    super.initState();
    _checkAndStartMotion();
  }

  void _checkAndStartMotion() {
    final appState = context.read<AppState>();
    if (appState.motionEffectsEnabled && !_motionService.isActive) {
      _motionService.start();
    }
  }

  @override
  void dispose() {
    // Don't stop the service here as it's shared
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        if (!appState.motionEffectsEnabled) {
          return widget.child;
        }

        return ValueListenableBuilder<MotionData>(
          valueListenable: _motionService.motionNotifier,
          builder: (context, motionData, _) {
            final offset = motionData.getParallaxOffset(widget.intensity);
            
            Widget result = Transform.translate(
              offset: offset,
              child: widget.child,
            );

            // Apply blur if enabled
            if (widget.enableBlur) {
              final blurAmount = motionData.getBlurAmount(widget.maxBlur);
              if (blurAmount > 0.1) {
                result = ImageFiltered(
                  imageFilter: ImageFilter.blur(
                    sigmaX: blurAmount,
                    sigmaY: blurAmount,
                  ),
                  child: result,
                );
              }
            }

            return result;
          },
        );
      },
    );
  }
}

/// Widget that applies depth-of-field blur based on motion
class MotionDepthBlur extends StatefulWidget {
  final Widget child;
  final double maxBlur;
  final double depthLevel; // 0 = foreground, 1 = background

  const MotionDepthBlur({
    super.key,
    required this.child,
    this.maxBlur = 5.0,
    this.depthLevel = 0.5,
  });

  @override
  State<MotionDepthBlur> createState() => _MotionDepthBlurState();
}

class _MotionDepthBlurState extends State<MotionDepthBlur> {
  final MotionService _motionService = MotionService();

  @override
  void initState() {
    super.initState();
    _checkAndStartMotion();
  }

  void _checkAndStartMotion() {
    final appState = context.read<AppState>();
    if (appState.motionEffectsEnabled && !_motionService.isActive) {
      _motionService.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        if (!appState.motionEffectsEnabled) {
          return widget.child;
        }

        return ValueListenableBuilder<MotionData>(
          valueListenable: _motionService.motionNotifier,
          builder: (context, motionData, _) {
            final blurAmount = motionData.getBlurAmount(widget.maxBlur) * widget.depthLevel;
            
            if (blurAmount < 0.1) {
              return widget.child;
            }

            return ImageFiltered(
              imageFilter: ImageFilter.blur(
                sigmaX: blurAmount,
                sigmaY: blurAmount,
              ),
              child: widget.child,
            );
          },
        );
      },
    );
  }
}

/// Widget that applies scale effect based on motion
class MotionScale extends StatefulWidget {
  final Widget child;
  final double baseScale;
  final double maxScale;

  const MotionScale({
    super.key,
    required this.child,
    this.baseScale = 1.0,
    this.maxScale = 1.05,
  });

  @override
  State<MotionScale> createState() => _MotionScaleState();
}

class _MotionScaleState extends State<MotionScale> {
  final MotionService _motionService = MotionService();

  @override
  void initState() {
    super.initState();
    _checkAndStartMotion();
  }

  void _checkAndStartMotion() {
    final appState = context.read<AppState>();
    if (appState.motionEffectsEnabled && !_motionService.isActive) {
      _motionService.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        if (!appState.motionEffectsEnabled) {
          return widget.child;
        }

        return ValueListenableBuilder<MotionData>(
          valueListenable: _motionService.motionNotifier,
          builder: (context, motionData, _) {
            final scale = motionData.getScaleFactor(widget.baseScale, widget.maxScale);
            
            return Transform.scale(
              scale: scale,
              child: widget.child,
            );
          },
        );
      },
    );
  }
}
