import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

class Player extends PositionComponent with HasGameRef<FlameGame> {
  final double moveSpeed = 200;
  late Paint _bodyPaint;
  late Paint _glowPaint;
  late Paint _enginePaint;
  late Paint _shieldPaint;

  // Animation properties
  double _engineFlicker = 0.0;
  double _shieldPulse = 0.0;
  double _hoverOffset = 0.0;
  double _wingAnimation = 0.0;
  bool _isMoving = false;
  double _tiltAngle = 0.0;

  // Engine trail particles
  final List<EngineParticle> _engineParticles = [];
  static const int maxEngineParticles = 15;

  Player();

  @override
  Future<void> onLoad() async {
    size = Vector2(60, 80);
    _initializePaints();
  }

  void _initializePaints() {
    // Sleek metallic body with blue-silver gradient
    _bodyPaint =
        Paint()
          ..shader = LinearGradient(
            colors: const [
              Color(0xFFE8F4FF), // Light blue-white
              Color(0xFF4FC3F7), // Sky blue
              Color(0xFF0288D1), // Deep blue
              Color(0xFF01579B), // Navy blue
            ],
            stops: const [0.0, 0.3, 0.7, 1.0],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(Rect.fromLTWH(0, 0, size.x, size.y));

    // Engine glow
    _enginePaint =
        Paint()
          ..shader = RadialGradient(
            colors: const [
              Color(0xFFFFFFFF), // White core
              Color(0xFF00E5FF), // Cyan
              Color(0xFF0091EA), // Blue
              Colors.transparent,
            ],
            stops: const [0.0, 0.4, 0.7, 1.0],
          ).createShader(Rect.fromLTWH(0, 0, size.x, size.y * 0.3))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    // Shield effect
    _shieldPaint =
        Paint()
          ..shader = RadialGradient(
            colors: [
              Color(0xFF00E5FF).withOpacity(0.0),
              Color(0xFF00E5FF).withOpacity(0.3),
              Color(0xFF0091EA).withOpacity(0.1),
              Colors.transparent,
            ],
            stops: const [0.0, 0.6, 0.8, 1.0],
          ).createShader(
            Rect.fromCenter(
              center: Offset(size.x / 2, size.y / 2),
              width: size.x * 2.5,
              height: size.y * 2.5,
            ),
          )
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
  }

  @override
  void onMount() {
    super.onMount();
    position = Vector2(
      (gameRef.size.x - size.x) / 2,
      gameRef.size.y - size.y - 30,
    );
  }

  @override
  void render(Canvas canvas) {
    canvas.save();

    // Apply hover and tilt transformations
    canvas.translate(size.x / 2, size.y / 2);
    canvas.rotate(_tiltAngle);
    canvas.translate(-size.x / 2, -size.y / 2 + _hoverOffset);

    // Draw shield effect
    _drawShield(canvas);

    // Draw engine particles
    _drawEngineParticles(canvas);

    // Draw main ship body
    _drawShipBody(canvas);

    // Draw engine glow
    _drawEngineGlow(canvas);

    // Draw cockpit and details
    _drawCockpitAndDetails(canvas);

    canvas.restore();
  }

  void _drawShield(Canvas canvas) {
    final shieldIntensity = 0.5 + math.sin(_shieldPulse) * 0.3;
    _shieldPaint.colorFilter = ColorFilter.mode(
      Colors.cyan.withOpacity(shieldIntensity * 0.4),
      BlendMode.plus,
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.x / 2, size.y / 2),
        width: size.x * 2.2,
        height: size.y * 1.8,
      ),
      _shieldPaint,
    );
  }

  void _drawEngineParticles(Canvas canvas) {
    for (final particle in _engineParticles) {
      final particlePaint =
          Paint()
            ..shader = RadialGradient(
              colors: [
                Color.lerp(
                  const Color(0xFF00E5FF),
                  const Color(0xFF0091EA),
                  particle.life,
                )!.withOpacity(particle.opacity),
                Colors.transparent,
              ],
            ).createShader(
              Rect.fromCenter(
                center: Offset(particle.position.x, particle.position.y),
                width: particle.size * 2,
                height: particle.size * 2,
              ),
            )
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

      canvas.drawCircle(
        Offset(particle.position.x, particle.position.y),
        particle.size,
        particlePaint,
      );
    }
  }

  void _drawShipBody(Canvas canvas) {
    final path = Path();

    // Sleek fighter ship silhouette
    final w = size.x;
    final h = size.y;

    // Main body - streamlined shape
    path.moveTo(w * 0.5, 0); // Nose
    path.quadraticBezierTo(w * 0.7, h * 0.15, w * 0.8, h * 0.3);
    path.lineTo(w * 0.9, h * 0.5); // Right wing tip
    path.quadraticBezierTo(w * 0.85, h * 0.6, w * 0.75, h * 0.65);
    path.lineTo(w * 0.65, h * 0.75);
    path.lineTo(w * 0.6, h * 0.95); // Right engine
    path.lineTo(w * 0.4, h * 0.95); // Left engine
    path.lineTo(w * 0.35, h * 0.75);
    path.lineTo(w * 0.25, h * 0.65);
    path.quadraticBezierTo(w * 0.15, h * 0.6, w * 0.1, h * 0.5);
    path.lineTo(w * 0.2, h * 0.3); // Left wing tip
    path.quadraticBezierTo(w * 0.3, h * 0.15, w * 0.5, 0);
    path.close();

    // Apply dynamic gradient based on movement
    final dynamicBodyPaint =
        Paint()
          ..shader = LinearGradient(
            colors: const [
              Color(0xFFE8F4FF),
              Color(0xFF4FC3F7),
              Color(0xFF0288D1),
              Color(0xFF01579B),
            ],
            stops: const [0.0, 0.3, 0.7, 1.0],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(path, dynamicBodyPaint);

    // Add metallic highlights
    final highlightPaint =
        Paint()
          ..shader = LinearGradient(
            colors: [
              Colors.white.withOpacity(0.6),
              Colors.white.withOpacity(0.0),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(Rect.fromLTWH(0, 0, w, h * 0.4))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    final highlightPath = Path();
    highlightPath.moveTo(w * 0.5, 0);
    highlightPath.quadraticBezierTo(w * 0.6, h * 0.1, w * 0.7, h * 0.25);
    highlightPath.quadraticBezierTo(w * 0.5, h * 0.3, w * 0.3, h * 0.25);
    highlightPath.quadraticBezierTo(w * 0.4, h * 0.1, w * 0.5, 0);

    canvas.drawPath(highlightPath, highlightPaint);
  }

  void _drawEngineGlow(Canvas canvas) {
    final engineIntensity = 0.8 + math.sin(_engineFlicker * 15) * 0.2;

    // Left engine
    final leftEnginePaint =
        Paint()
          ..shader = RadialGradient(
            colors: [
              Color(0xFFFFFFFF).withOpacity(engineIntensity),
              Color(0xFF00E5FF).withOpacity(engineIntensity * 0.8),
              Color(0xFF0091EA).withOpacity(engineIntensity * 0.4),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCenter(
              center: Offset(size.x * 0.35, size.y * 0.95),
              width: 20,
              height: 30,
            ),
          )
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.x * 0.35, size.y * 0.95),
        width: 15,
        height: 25,
      ),
      leftEnginePaint,
    );

    // Right engine
    final rightEnginePaint =
        Paint()
          ..shader = RadialGradient(
            colors: [
              Color(0xFFFFFFFF).withOpacity(engineIntensity),
              Color(0xFF00E5FF).withOpacity(engineIntensity * 0.8),
              Color(0xFF0091EA).withOpacity(engineIntensity * 0.4),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCenter(
              center: Offset(size.x * 0.65, size.y * 0.95),
              width: 20,
              height: 30,
            ),
          )
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.x * 0.65, size.y * 0.95),
        width: 15,
        height: 25,
      ),
      rightEnginePaint,
    );
  }

  void _drawCockpitAndDetails(Canvas canvas) {
    // Cockpit glass
    final cockpitPaint =
        Paint()
          ..shader = RadialGradient(
            colors: const [
              Color(0xFF87CEEB), // Sky blue
              Color(0xFF4682B4), // Steel blue
              Color(0xFF2F4F4F), // Dark slate gray
            ],
          ).createShader(
            Rect.fromCenter(
              center: Offset(size.x * 0.5, size.y * 0.25),
              width: size.x * 0.3,
              height: size.y * 0.2,
            ),
          )
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.x * 0.5, size.y * 0.25),
        width: size.x * 0.25,
        height: size.y * 0.15,
      ),
      cockpitPaint,
    );

    // Wing details
    final detailPaint =
        Paint()
          ..color = const Color(0xFF0288D1)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;

    // Left wing detail
    canvas.drawLine(
      Offset(size.x * 0.2, size.y * 0.4),
      Offset(size.x * 0.35, size.y * 0.5),
      detailPaint,
    );

    // Right wing detail
    canvas.drawLine(
      Offset(size.x * 0.8, size.y * 0.4),
      Offset(size.x * 0.65, size.y * 0.5),
      detailPaint,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Update animations
    _engineFlicker += dt;
    _shieldPulse += dt * 3;
    _hoverOffset = math.sin(_engineFlicker * 2) * 1.5;
    _wingAnimation += dt * 4;

    // Update tilt based on movement
    if (_isMoving) {
      _tiltAngle = math.sin(_wingAnimation) * 0.05; // Subtle banking effect
    } else {
      _tiltAngle = _tiltAngle * 0.95; // Smooth return to level
    }

    // Update engine particles
    _updateEngineParticles(dt);

    // Add new engine particles
    if (_engineParticles.length < maxEngineParticles) {
      _addEngineParticle();
    }
  }

  void _updateEngineParticles(double dt) {
    _engineParticles.removeWhere((particle) {
      particle.update(dt);
      return particle.life >= 1.0;
    });
  }

  void _addEngineParticle() {
    final random = math.Random();

    // Add particles from both engines
    for (int i = 0; i < 2; i++) {
      final engineX = size.x * (i == 0 ? 0.35 : 0.65);
      _engineParticles.add(
        EngineParticle(
          position: Vector2(
            engineX + (random.nextDouble() - 0.5) * 8,
            size.y * 0.95 + random.nextDouble() * 5,
          ),
          velocity: Vector2(
            (random.nextDouble() - 0.5) * 20,
            50 + random.nextDouble() * 30,
          ),
          size: 2 + random.nextDouble() * 3,
        ),
      );
    }
  }

  void setMoving(bool moving) {
    _isMoving = moving;
  }

  Rect toRect() => Rect.fromLTWH(position.x, position.y, size.x, size.y);
}

class EngineParticle {
  Vector2 position;
  Vector2 velocity;
  double size;
  double life = 0.0;
  double opacity = 1.0;

  EngineParticle({
    required this.position,
    required this.velocity,
    required this.size,
  });

  void update(double dt) {
    position += velocity * dt;
    life += dt * 2;
    opacity = (1.0 - life).clamp(0.0, 1.0);
    size *= 0.98; // Particles shrink over time
  }
}
