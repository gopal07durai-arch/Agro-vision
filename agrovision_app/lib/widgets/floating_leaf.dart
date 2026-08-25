import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Agriculture-themed floating leaf background animation.
/// Used behind the home screen hero.
class FloatingLeafBackground extends StatefulWidget {
  const FloatingLeafBackground({super.key});

  @override
  State<FloatingLeafBackground> createState() => _FloatingLeafBackgroundState();
}

class _FloatingLeafBackgroundState extends State<FloatingLeafBackground>
    with TickerProviderStateMixin {
  final List<_LeafParticle> _particles = [];
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    final random = math.Random();

    // Generate 8 leaf particles
    for (int i = 0; i < 8; i++) {
      _particles.add(_LeafParticle(
        x: random.nextDouble(),
        y: random.nextDouble(),
        size: 20 + random.nextDouble() * 25,
        speedX: (random.nextDouble() - 0.5) * 0.15,
        speedY: -0.05 - random.nextDouble() * 0.1,
        rotation: random.nextDouble() * math.pi * 2,
        rotationSpeed: (random.nextDouble() - 0.5) * 0.03,
        opacity: 0.06 + random.nextDouble() * 0.08,
        emoji: _leafEmojis[random.nextInt(_leafEmojis.length)],
        delay: Duration(milliseconds: random.nextInt(3000)),
      ));
    }

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  static const List<String> _leafEmojis = ['🍃', '🌿', '🌱', '🍀', '🌾'];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return Stack(
          children: _particles.map((p) {
            final t = (_controller.value + p.delay.inMilliseconds / 10000) % 1.0;
            final x = (p.x + p.speedX * t * 10) % 1.0;
            final y = (p.y + p.speedY * t * 10) % 1.0;
            final rot = p.rotation + p.rotationSpeed * t * 10;

            return Positioned(
              left: x * size.width,
              top: y * size.height,
              child: Opacity(
                opacity: p.opacity,
                child: Transform.rotate(
                  angle: rot,
                  child: Text(
                    p.emoji,
                    style: TextStyle(fontSize: p.size),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _LeafParticle {
  final double x;
  final double y;
  final double size;
  final double speedX;
  final double speedY;
  final double rotation;
  final double rotationSpeed;
  final double opacity;
  final String emoji;
  final Duration delay;

  const _LeafParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.speedX,
    required this.speedY,
    required this.rotation,
    required this.rotationSpeed,
    required this.opacity,
    required this.emoji,
    required this.delay,
  });
}
