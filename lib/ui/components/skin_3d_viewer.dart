import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

class Skin3DViewer extends StatefulWidget {
  final double confidence;
  final String riskLevel;
  final Color riskColor;
  final List<List<double>>? heatmapGrid;
  final String? predictedClass;
  final Uint8List? capturedImage;
  final ValueNotifier<Offset?>? selectedPointNotifier;

  const Skin3DViewer({
    super.key,
    required this.confidence,
    required this.riskLevel,
    required this.riskColor,
    this.heatmapGrid,
    this.predictedClass,
    this.capturedImage,
    this.selectedPointNotifier,
  });

  @override
  State<Skin3DViewer> createState() => _Skin3DViewerState();
}

class _Skin3DViewerState extends State<Skin3DViewer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _scale = 1.0;
  Offset _offset = Offset.zero;
  Offset? _selectedHotspot;
  double? _selectedIntensity;
  ui.Image? _textureImage;
  double _depthIntensity = 1.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _loadTexture();
    
    // Listen to external selection changes
    widget.selectedPointNotifier?.addListener(_onExternalSelection);
  }

  @override
  void dispose() {
    widget.selectedPointNotifier?.removeListener(_onExternalSelection);
    _controller.dispose();
    _textureImage?.dispose();
    super.dispose();
  }

  void _onExternalSelection() {
    final point = widget.selectedPointNotifier?.value;
    if (point != null && mounted) {
      // Animate to the selected point
      setState(() {
        _selectedHotspot = point;
        // Get intensity at this point
        if (widget.heatmapGrid != null) {
          final gridSize = widget.heatmapGrid!.length;
          final gridX = (point.dx * gridSize).clamp(0, gridSize - 1).toInt();
          final gridY = (point.dy * gridSize).clamp(0, gridSize - 1).toInt();
          _selectedIntensity = widget.heatmapGrid![gridY][gridX];
          _depthIntensity = _selectedIntensity!;
        }
      });
      
      // Pulse animation
      _controller.forward(from: 0.0);
    }
  }

  Future<void> _loadTexture() async {
    if (widget.capturedImage != null) {
      final codec = await ui.instantiateImageCodec(widget.capturedImage!);
      final frame = await codec.getNextFrame();
      if (mounted) {
        setState(() {
          _textureImage = frame.image;
        });
      }
    }
  }

  void _handleTap(TapDownDetails details, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final tapPos = details.localPosition;
    final distance = (tapPos - center).distance;
    final radius = size.width * 0.35;

    // Check if tap is within sphere
    if (distance < radius * 1.2 && widget.heatmapGrid != null) {
      // Convert tap position to heatmap coordinates
      final gridSize = widget.heatmapGrid!.length;
      final normalizedX = ((tapPos.dx - center.dx) / radius + 1) / 2;
      final normalizedY = ((tapPos.dy - center.dy) / radius + 1) / 2;
      
      final gridX = (normalizedX * gridSize).clamp(0, gridSize - 1).toInt();
      final gridY = (normalizedY * gridSize).clamp(0, gridSize - 1).toInt();
      
      final intensity = widget.heatmapGrid![gridY][gridX];
      
      setState(() {
        _selectedHotspot = tapPos;
        _selectedIntensity = intensity;
      });

      // Auto-hide after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _selectedHotspot = null;
            _selectedIntensity = null;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onScaleStart: (details) {
        // Store initial values for pinch/pan
      },
      onScaleUpdate: (details) {
        setState(() {
          _scale = (_scale * details.scale).clamp(0.5, 3.0);
          _offset += details.focalPointDelta;
        });
      },
      onTapDown: (details) => _handleTap(details, const Size(300, 300)),
      child: Stack(
        children: [
          // Main enhanced 2D visualization
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: _scale,
                child: Transform.translate(
                  offset: _offset,
                  child: CustomPaint(
                    size: const Size(300, 300),
                    painter: EnhancedSkin2DPainter(
                      confidence: widget.confidence,
                      riskColor: widget.riskColor,
                      heatmapGrid: widget.heatmapGrid,
                      textureImage: _textureImage,
                      selectedPoint: _selectedHotspot,
                      pulseAnimation: _controller.value,
                      depthIntensity: _depthIntensity,
                    ),
                  ),
                ),
              );
            },
          ),
          
          // Hotspot info popup with enhanced details
          if (_selectedHotspot != null && _selectedIntensity != null)
            Positioned(
              left: 150 - 80,
              top: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.9),
                      Colors.black.withValues(alpha: 0.85),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _getIntensityColor(_selectedIntensity!).withValues(alpha: 0.6),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _getIntensityColor(_selectedIntensity!).withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _getIntensityColor(_selectedIntensity!),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: _getIntensityColor(_selectedIntensity!),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.predictedClass ?? 'Unknown',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow('Attention', '${(_selectedIntensity! * 100).toStringAsFixed(0)}%'),
                    _buildDetailRow('Confidence', '${(widget.confidence * 100).toStringAsFixed(0)}%'),
                    _buildDetailRow('Risk', widget.riskLevel),
                  ],
                ),
              ),
            ),
          
          // Instructions
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Pinch to zoom • Tap to inspect',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getIntensityColor(double intensity) {
    if (intensity < 0.25) return Colors.blue;
    if (intensity < 0.5) return Colors.green;
    if (intensity < 0.75) return Colors.yellow;
    return Colors.red;
  }
}

class EnhancedSkin2DPainter extends CustomPainter {
  final double confidence;
  final Color riskColor;
  final List<List<double>>? heatmapGrid;
  final ui.Image? textureImage;
  final Offset? selectedPoint;
  final double pulseAnimation;
  final double depthIntensity;

  EnhancedSkin2DPainter({
    required this.confidence,
    required this.riskColor,
    this.heatmapGrid,
    this.textureImage,
    this.selectedPoint,
    required this.pulseAnimation,
    required this.depthIntensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    
    // Draw the actual captured image
    if (textureImage != null) {
      final paint = Paint()
        ..filterQuality = FilterQuality.high;
      
      canvas.drawImageRect(
        textureImage!,
        Rect.fromLTWH(0, 0, textureImage!.width.toDouble(), textureImage!.height.toDouble()),
        rect,
        paint,
      );
    }
    
    // Draw heatmap overlay with depth effect
    if (heatmapGrid != null) {
      final gridSize = heatmapGrid!.length;
      final cellWidth = size.width / gridSize;
      final cellHeight = size.height / gridSize;
      
      for (int y = 0; y < gridSize; y++) {
        for (int x = 0; x < gridSize; x++) {
          final intensity = heatmapGrid![y][x];
          
          if (intensity > 0.3) {
            // Draw depth effect (shadow + glow)
            final cellRect = Rect.fromLTWH(
              x * cellWidth,
              y * cellHeight,
              cellWidth,
              cellHeight,
            );
            
            final color = _heatmapValueToColor(intensity);
            
            // Depth shadow
            final shadowPaint = Paint()
              ..color = Colors.black.withValues(alpha: intensity * 0.3)
              ..maskFilter = MaskFilter.blur(BlurStyle.normal, intensity * 8);
            canvas.drawRect(cellRect.shift(Offset(2, 2)), shadowPaint);
            
            // Glow effect
            final glowPaint = Paint()
              ..color = color.withValues(alpha: intensity * 0.5)
              ..maskFilter = MaskFilter.blur(BlurStyle.normal, intensity * 12);
            canvas.drawRect(cellRect, glowPaint);
            
            // Highlight high-intensity areas
            if (intensity > 0.7) {
              final highlightPaint = Paint()
                ..color = Colors.white.withValues(alpha: (intensity - 0.7) * 0.4)
                ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
              canvas.drawCircle(cellRect.center, cellWidth * 0.6, highlightPaint);
            }
          }
        }
      }
    }
    
    // Draw selected point with pulsing effect
    if (selectedPoint != null && heatmapGrid != null) {
      final gridSize = heatmapGrid!.length;
      final gridX = (selectedPoint!.dx * gridSize).clamp(0, gridSize - 1).toInt();
      final gridY = (selectedPoint!.dy * gridSize).clamp(0, gridSize - 1).toInt();
      final intensity = heatmapGrid![gridY][gridX];
      
      final actualX = (gridX / gridSize) * size.width;
      final actualY = (gridY / gridSize) * size.height;
      final center = Offset(actualX, actualY);
      
      // Pulsing ring
      final pulseRadius = 20 + (pulseAnimation * 15);
      final pulsePaint = Paint()
        ..color = _heatmapValueToColor(intensity).withValues(alpha: 1.0 - pulseAnimation)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawCircle(center, pulseRadius, pulsePaint);
      
      // Inner glow
      final glowPaint = Paint()
        ..color = _heatmapValueToColor(intensity).withValues(alpha: 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
      canvas.drawCircle(center, 25, glowPaint);
      
      // Center marker
      final markerPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(center, 15, markerPaint);
      
      // Crosshair
      canvas.drawLine(
        Offset(center.dx - 10, center.dy),
        Offset(center.dx + 10, center.dy),
        markerPaint,
      );
      canvas.drawLine(
        Offset(center.dx, center.dy - 10),
        Offset(center.dx, center.dy + 10),
        markerPaint,
      );
    }
    
    // Draw border
    final borderPaint = Paint()
      ..color = riskColor.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(rect, borderPaint);
  }

  Color _heatmapValueToColor(double value) {
    if (value < 0.25) {
      final t = value / 0.25;
      return Color.fromRGBO(0, (t * 255).toInt(), 255, 0.9);
    } else if (value < 0.5) {
      final t = (value - 0.25) / 0.25;
      return Color.fromRGBO(0, 255, (255 * (1 - t)).toInt(), 0.9);
    } else if (value < 0.75) {
      final t = (value - 0.5) / 0.25;
      return Color.fromRGBO((t * 255).toInt(), 255, 0, 0.9);
    } else {
      final t = (value - 0.75) / 0.25;
      return Color.fromRGBO(255, (255 * (1 - t)).toInt(), 0, 0.9);
    }
  }

  @override
  bool shouldRepaint(EnhancedSkin2DPainter oldDelegate) => true;
}

// Keep old painter for reference but rename
class Skin3DPainter extends CustomPainter {
  final double rotationX;
  final double rotationY;
  final double confidence;
  final Color riskColor;
  final List<List<double>>? heatmapGrid;
  final ui.Image? textureImage;

  Skin3DPainter({
    required this.rotationX,
    required this.rotationY,
    required this.confidence,
    required this.riskColor,
    this.heatmapGrid,
    this.textureImage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseSize = size.width * 0.7;

    // Create 3D surface mesh (flat surface with depth from heatmap)
    final int gridResolution = 30;
    final points = <_Point3D>[];
    final projectedPoints = <Offset>[];

    // Generate 3D mesh points
    for (int y = 0; y < gridResolution; y++) {
      for (int x = 0; x < gridResolution; x++) {
        // Normalized coordinates (0 to 1)
        final u = x / (gridResolution - 1);
        final v = y / (gridResolution - 1);

        // Map to surface coordinates (-1 to 1)
        final surfaceX = (u - 0.5) * baseSize;
        final surfaceY = (v - 0.5) * baseSize;

        // Get depth from heatmap (creates 3D relief)
        double depth = 0.0;
        if (heatmapGrid != null) {
          final gridSize = heatmapGrid!.length;
          final gridX = (u * gridSize).clamp(0, gridSize - 1).toInt();
          final gridY = (v * gridSize).clamp(0, gridSize - 1).toInt();
          final heatValue = heatmapGrid![gridY][gridX];
          // Higher heatmap values = more depth (raised surface)
          depth = heatValue * 50.0;
        }

        points.add(_Point3D(surfaceX, surfaceY, depth, u, v));
      }
    }

    // Apply 3D transformations and project to 2D
    for (final point in points) {
      final rotated = _rotate3D(point.x, point.y, point.z, rotationX, rotationY);
      
      // Perspective projection
      final distance = 400.0;
      final scale = distance / (distance + rotated.z);
      final projected = Offset(
        center.dx + rotated.x * scale,
        center.dy + rotated.y * scale,
      );
      projectedPoints.add(projected);
    }

    // Draw mesh with texture and heatmap overlay
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..filterQuality = FilterQuality.high;

    // Draw quads
    for (int y = 0; y < gridResolution - 1; y++) {
      for (int x = 0; x < gridResolution - 1; x++) {
        final i = y * gridResolution + x;
        
        final p1 = projectedPoints[i];
        final p2 = projectedPoints[i + 1];
        final p3 = projectedPoints[i + gridResolution];
        final p4 = projectedPoints[i + gridResolution + 1];

        // Get depth for lighting
        final avgZ = (points[i].z + points[i + 1].z + 
                     points[i + gridResolution].z + points[i + gridResolution + 1].z) / 4;
        
        // Calculate color based on texture and heatmap
        Color quadColor;
        if (heatmapGrid != null) {
          final gridSize = heatmapGrid!.length;
          final u = points[i].u;
          final v = points[i].v;
          final gridX = (u * gridSize).clamp(0, gridSize - 1).toInt();
          final gridY = (v * gridSize).clamp(0, gridSize - 1).toInt();
          final heatValue = heatmapGrid![gridY][gridX];
          
          quadColor = _heatmapValueToColor(heatValue);
          
          // Add lighting based on depth
          final lighting = (1.0 + avgZ / 50.0).clamp(0.7, 1.3);
          quadColor = Color.fromRGBO(
            ((quadColor.r * 255.0) * lighting).clamp(0, 255).toInt(),
            ((quadColor.g * 255.0) * lighting).clamp(0, 255).toInt(),
            ((quadColor.b * 255.0) * lighting).clamp(0, 255).toInt(),
            0.9,
          );
        } else {
          quadColor = Color.lerp(
            Colors.blue.shade200,
            riskColor,
            confidence,
          )!;
        }

        // Draw quad
        paint.color = quadColor;
        final path = Path()
          ..moveTo(p1.dx, p1.dy)
          ..lineTo(p2.dx, p2.dy)
          ..lineTo(p4.dx, p4.dy)
          ..lineTo(p3.dx, p3.dy)
          ..close();
        canvas.drawPath(path, paint);

        // Draw mesh lines for 3D effect
        paint
          ..color = Colors.white.withValues(alpha: 0.15)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5;
        canvas.drawPath(path, paint);
        paint.style = PaintingStyle.fill;
      }
    }

    // Draw glow around high-intensity areas
    if (heatmapGrid != null) {
      final glowPaint = Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
      
      for (int i = 0; i < points.length; i++) {
        final gridSize = heatmapGrid!.length;
        final u = points[i].u;
        final v = points[i].v;
        final gridX = (u * gridSize).clamp(0, gridSize - 1).toInt();
        final gridY = (v * gridSize).clamp(0, gridSize - 1).toInt();
        final heatValue = heatmapGrid![gridY][gridX];
        
        if (heatValue > 0.7) {
          glowPaint.color = _heatmapValueToColor(heatValue).withValues(alpha: 0.4);
          canvas.drawCircle(projectedPoints[i], 8, glowPaint);
        }
      }
    }
  }

  vector.Vector3 _rotate3D(double x, double y, double z, double rx, double ry) {
    // Rotation around X axis
    final cosX = math.cos(rx);
    final sinX = math.sin(rx);
    final y1 = y * cosX - z * sinX;
    final z1 = y * sinX + z * cosX;

    // Rotation around Y axis
    final cosY = math.cos(ry);
    final sinY = math.sin(ry);
    final x2 = x * cosY + z1 * sinY;
    final z2 = -x * sinY + z1 * cosY;

    return vector.Vector3(x2, y1, z2);
  }

  Color _heatmapValueToColor(double value) {
    if (value < 0.25) {
      // Blue to Cyan
      final t = value / 0.25;
      return Color.fromRGBO(0, (t * 255).toInt(), 255, 0.9);
    } else if (value < 0.5) {
      // Cyan to Green
      final t = (value - 0.25) / 0.25;
      return Color.fromRGBO(0, 255, (255 * (1 - t)).toInt(), 0.9);
    } else if (value < 0.75) {
      // Green to Yellow
      final t = (value - 0.5) / 0.25;
      return Color.fromRGBO((t * 255).toInt(), 255, 0, 0.9);
    } else {
      // Yellow to Red
      final t = (value - 0.75) / 0.25;
      return Color.fromRGBO(255, (255 * (1 - t)).toInt(), 0, 0.9);
    }
  }

  @override
  bool shouldRepaint(Skin3DPainter oldDelegate) => true;
}

class _Point3D {
  final double x;
  final double y;
  final double z;
  final double u; // Texture coordinate
  final double v; // Texture coordinate

  _Point3D(this.x, this.y, this.z, this.u, this.v);
}
