import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

class Skin3DViewer extends StatefulWidget {
  final double confidence;
  final String riskLevel;
  final Color riskColor;

  const Skin3DViewer({
    super.key,
    required this.confidence,
    required this.riskLevel,
    required this.riskColor,
  });

  @override
  State<Skin3DViewer> createState() => _Skin3DViewerState();
}

class _Skin3DViewerState extends State<Skin3DViewer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _rotationX = 0.3;
  double _rotationY = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            size: const Size(300, 300),
            painter: Skin3DPainter(
              rotationX: _rotationX,
              rotationY: _rotationY + _controller.value * 2 * math.pi,
              confidence: widget.confidence,
              riskColor: widget.riskColor,
            ),
          );
        },
      ),
    );
  }
}

class Skin3DPainter extends CustomPainter {
  final double rotationX;
  final double rotationY;
  final double confidence;
  final Color riskColor;

  Skin3DPainter({
    required this.rotationX,
    required this.rotationY,
    required this.confidence,
    required this.riskColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.35;

    // Create 3D sphere mesh
    final int latitudes = 20;
    final int longitudes = 20;

    final points = <Offset>[];
    final colors = <Color>[];

    for (int lat = 0; lat < latitudes; lat++) {
      final theta = (lat / latitudes) * math.pi;
      for (int lon = 0; lon < longitudes; lon++) {
        final phi = (lon / longitudes) * 2 * math.pi;

        // 3D coordinates
        var x = radius * math.sin(theta) * math.cos(phi);
        var y = radius * math.sin(theta) * math.sin(phi);
        var z = radius * math.cos(theta);

        // Apply rotations
        final point = _rotate3D(x, y, z, rotationX, rotationY);

        // Project to 2D
        final scale = 1.0 / (1.0 + point.z / 500);
        final projected = Offset(
          center.dx + point.x * scale,
          center.dy + point.y * scale,
        );

        points.add(projected);

        // Color based on confidence and position
        final intensity = (math.cos(theta) + 1) / 2;
        final colorIntensity = confidence * intensity;
        colors.add(Color.lerp(
          Colors.blue.shade100,
          riskColor,
          colorIntensity,
        )!);
      }
    }

    // Draw mesh
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < points.length - longitudes - 1; i++) {
      if ((i + 1) % longitudes == 0) continue;

      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = points[i + longitudes];
      final p4 = points[i + longitudes + 1];

      // Draw quad as two triangles
      paint.color = colors[i].withValues(alpha: 0.8);

      final path = Path()
        ..moveTo(p1.dx, p1.dy)
        ..lineTo(p2.dx, p2.dy)
        ..lineTo(p4.dx, p4.dy)
        ..lineTo(p3.dx, p3.dy)
        ..close();

      canvas.drawPath(path, paint);

      // Draw edges for mesh effect
      paint
        ..color = Colors.white.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5;
      canvas.drawPath(path, paint);
      paint.style = PaintingStyle.fill;
    }

    // Draw hotspot (affected area)
    final hotspotPaint = Paint()
      ..color = riskColor.withValues(alpha: 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

    canvas.drawCircle(
      Offset(center.dx + 20, center.dy - 10),
      radius * 0.3 * confidence,
      hotspotPaint,
    );

    // Draw glow effect
    final glowPaint = Paint()
      ..color = riskColor.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);

    canvas.drawCircle(center, radius * 1.2, glowPaint);
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

  @override
  bool shouldRepaint(Skin3DPainter oldDelegate) => true;
}
