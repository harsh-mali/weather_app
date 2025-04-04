import 'package:flutter/material.dart';
import 'dart:math' as math;

class AnimatedBackground extends StatefulWidget {
  final Widget child;
  final String weatherCondition;
  
  const AnimatedBackground({
    super.key, 
    required this.child,
    required this.weatherCondition,
  });

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Particle> particles = List.generate(20, (index) => Particle());

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: BackgroundPainter(
                  animation: _controller,
                  particles: particles,
                  weatherCondition: widget.weatherCondition,
                ),
                size: Size.infinite,
              );
            },
          ),
          widget.child,
        ],
      ),
    );
  }
}

class BackgroundPainter extends CustomPainter {
  final Animation<double> animation;
  final List<Particle> particles;
  final String weatherCondition;

  BackgroundPainter({
    required this.animation, 
    required this.particles,
    required this.weatherCondition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()..color = Colors.black;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);

    for (var particle in particles) {
      particle.update(animation.value, size, weatherCondition);
      
      final Color particleColor = _getParticleColor(weatherCondition);
      
      // Outer glow - larger and softer
      final outerGlowPaint = Paint()
        ..color = particleColor.withOpacity(0.08 * particle.opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25);
      
      canvas.drawCircle(
        Offset(particle.x, particle.y),
        particle.size * 4,
        outerGlowPaint,
      );

      // Middle glow - brighter and more defined
      final middleGlowPaint = Paint()
        ..color = particleColor.withOpacity(0.15 * particle.opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      
      canvas.drawCircle(
        Offset(particle.x, particle.y),
        particle.size * 2.5,
        middleGlowPaint,
      );

      // Inner glow - intense but not harsh
      final innerGlowPaint = Paint()
        ..color = particleColor.withOpacity(0.3 * particle.opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      
      canvas.drawCircle(
        Offset(particle.x, particle.y),
        particle.size * 1.5,
        innerGlowPaint,
      );

      // Bright core
      final corePaint = Paint()
        ..color = particleColor.withOpacity(0.7 * particle.opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(particle.x, particle.y),
        particle.size,
        corePaint,
      );
    }
  }

  Color _getParticleColor(String condition) {
    condition = condition.toLowerCase();
    if (condition.contains('rain')) {
      return Colors.blue[300] ?? Colors.blue; // Lighter blue
    } else if (condition.contains('snow')) {
      return Colors.white;
    } else if (condition.contains('thunder')) {
      return Colors.amber[300] ?? Colors.amber; // Softer yellow
    } else if (condition.contains('clear')) {
      return Colors.orange[200] ?? Colors.orange; // Lighter orange
    } else if (condition.contains('cloud')) {
      return Colors.blueGrey[100] ?? Colors.blueGrey; // Light grey
    }
    return Colors.white;
  }

  @override
  bool shouldRepaint(BackgroundPainter oldDelegate) => true;
}

class Particle {
  double x = 0;
  double y = 0;
  double size = 0;
  double speed = 0;
  double opacity = 0;
  double direction = 0;

  Particle() {
    reset();
  }

  void reset() {
    final random = math.Random();
    x = random.nextDouble() * 400;
    y = random.nextDouble() * 800;
    size = random.nextDouble() * 3 + 1.5; // Slightly smaller for better glow effect
    speed = random.nextDouble() * 0.4 + 0.2;
    opacity = random.nextDouble() * 0.4 + 0.6; // Higher base opacity
    direction = random.nextDouble() * 2 * math.pi;
  }

  void update(double delta, Size size, String weatherCondition) {
    final condition = weatherCondition.toLowerCase();
    
    if (condition.contains('rain')) {
      y += speed * 5;
      opacity = math.sin(delta * math.pi * 4) * 0.3 + 0.7; // Faster pulsing
      if (y > size.height) {
        y = 0;
        x = math.Random().nextDouble() * size.width;
      }
    } else if (condition.contains('snow')) {
      y += speed * 1.2;
      x += math.sin(delta * 3) * speed * 0.5;
      opacity = math.sin(delta * math.pi * 2) * 0.2 + 0.8; // Gentle pulsing
      if (y > size.height) {
        y = 0;
        x = math.Random().nextDouble() * size.width;
      }
    } else if (condition.contains('thunder')) {
      x += math.cos(direction) * speed * 2.5;
      y += math.sin(direction) * speed * 2.5;
      opacity = math.Random().nextDouble() * 0.5 + 0.5; // Flash effect
    } else if (condition.contains('cloud')) {
      x += math.cos(direction) * speed * 0.4;
      y += math.sin(direction) * speed * 0.4;
      opacity = math.sin(delta * math.pi) * 0.2 + 0.8; // Steady glow
    } else {
      x += math.cos(direction) * speed;
      y += math.sin(direction) * speed;
      opacity = math.sin(delta * math.pi * 2) * 0.3 + 0.7; // Normal pulsing
    }

    // Screen wrapping
    if (x < 0) x = size.width;
    if (x > size.width) x = 0;
    if (y < 0) y = size.height;
    if (y > size.height) y = 0;
  }
} 