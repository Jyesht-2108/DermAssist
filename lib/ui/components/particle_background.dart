import 'dart:math' as math;
import 'package:flutter/material.dart';

class ParticleBackground extends StatefulWidget {
  final Widget child;
  final int particleCount;
  final Color particleColor;

  const ParticleBackground({
    super.key,
    required this.child,
    this.particleCount = 50,
    this.particleColor = Colors.white,
  });

  @override
  State<ParticleBackground> createState() => _ParticleBackgroundState();
}

class _ParticleBackgroundState extends State<ParticleBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Particle> particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    particles = List.generate(
      widget.particleCount,
      (index) => Particle(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: ParticlePainter(
                particles: particles,
                animation: _controller.value,
                color: widget.particleColor,
              ),
              size: Size.infinite,
            );
          },
        ),
        widget.child,
      ],
    );
  }
}

class Particle {
  double x;
  double y;
  double vx;
  double vy;
  double size;
  double opacity;

  Particle()
      : x = math.Random().nextDouble(),
        y = math.Random().nextDouble(),
        vx = (math.Random().nextDouble() - 0.5) * 0.02,
        vy = (math.Random().nextDouble() - 0.5) * 0.02,
        size = math.Random().nextDouble() * 3 + 1,
        opacity = math.Random().nextDouble() * 0.5 + 0.2;

  void update() {
    x += vx;
    y += vy;

    if (x < 0 || x > 1) vx *= -1;
    if (y < 0 || y > 1) vy *= -1;

    x = x.clamp(0.0, 1.0);
    y = y.clamp(0.0, 1.0);
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double animation;
  final Color color;

  ParticlePainter({
    required this.particles,
    required this.animation,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;

    for (var particle in particles) {
      particle.update();

      final position = Offset(
        particle.x * size.width,
        particle.y * size.height,
      );

      paint.color = color.withValues(alpha: particle.opacity);
      canvas.drawCircle(position, particle.size, paint);

      // Draw connections
      for (var other in particles) {
        final otherPos = Offset(
          other.x * size.width,
          other.y * size.height,
        );

        final distance = (position - otherPos).distance;
        if (distance < 100) {
          paint
            ..color = color.withValues(alpha: (1 - distance / 100) * 0.2)
            ..strokeWidth = 0.5;
          canvas.drawLine(position, otherPos, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => true;
}
