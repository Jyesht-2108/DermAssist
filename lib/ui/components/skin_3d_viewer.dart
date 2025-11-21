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

  const Skin3DViewer({
    super.key,
    required this.confidence,
    required this.riskLevel,
    required this.riskColor,
    this.heatmapGrid,
    this.predictedClass,
    this.capturedImage,
  });

  @override
  State<Skin3DViewer> createState() => _Skin3DViewerState();
}

class _Skin3DViewerState extends State<Skin3DViewer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _rotationX = 0.4;
  double _rotationY = 0.0;
  Offset? _selectedHotspot;
  double? _selectedIntensity;
  ui.Image? _textureImage;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();
    _loadTexture();
  }

  @override
  void dispose() {
    _controller.dispose();
    _textureImage?.dispose();
    super.dispose();
  }

  Future<void> _loadTexture() async {
    if (widget.capturedImage != null) {
      final codec = await ui.instantiateImageCodec(widget.capturedImage!);
      final frame = await codec.getNextFrame();
      setState(() {
        _textureImage = frame.image;
      });
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
      onPanUpdate: (details) {
        setState(() {
          _rotationY += details.delta.dx * 0.01;
          _rotationX += details.delta.dy * 0.01;
          _rotationX = _rotationX.clamp(-math.pi / 2, math.pi / 2);
        });
      },
      onTapDown: (details) => _handleTap(details, const Size(300, 300)),
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                size: const Size(300, 300),
                painter: Skin3DPainter(
                  rotationX: _rotationX,
                  rotationY: _rotationY + _controller.value * 0.5 * math.pi,
                  confidence: widget.confidence,
                  riskColor: widget.riskColor,
                  heatmapGrid: widget.heatmapGrid,
                  textureImage: _textureImage,
                ),
              );
            },
          ),
          // Hotspot info popup
          if (_selectedHotspot != null && _selectedIntensity != null)
            Positioned(
              left: _selectedHotspot!.dx - 60,
              top: _selectedHotspot!.dy - 80,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.predictedClass ?? 'Unknown',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Intensity: ${(_selectedIntensity! * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      'Confidence: ${(widget.confidence * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

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
