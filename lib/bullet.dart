import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class Bullet extends RectangleComponent {
  bool isActive = false;
  static const double speed = 700.0;

  // Animation properties for enhanced visuals
  late double _glowIntensity = 1.0;
  late double _trailOffset = 0.0;
  late double _sparkleRotation = 0.0;
  final List<Vector2> _trailPositions = [];
  static const int maxTrailLength = 8;

  Bullet({super.position, required IconData iconData})
    : super(size: Vector2(8, 24), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    // Initialize trail positions
    for (int i = 0; i < maxTrailLength; i++) {
      _trailPositions.add(Vector2.copy(position));
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.save();

    // Draw energy trail
    _drawEnergyTrail(canvas);

    // Draw main bullet body with multiple layers
    _drawBulletCore(canvas);
    _drawBulletGlow(canvas);
    _drawSparkles(canvas);

    canvas.restore();
  }

  void _drawEnergyTrail(Canvas canvas) {
    // Draw fading energy trail
    for (int i = 0; i < _trailPositions.length - 1; i++) {
      final alpha = (1.0 - (i / _trailPositions.length)) * 0.6;
      final trailSize = size.x * (0.8 - (i * 0.08));

      final trailPaint =
          Paint()
            ..shader = RadialGradient(
              colors: [
                Color.lerp(
                  const Color(0xFF00FFFF),
                  const Color(0xFF0080FF),
                  i / _trailPositions.length,
                )!.withOpacity(alpha),
                Colors.transparent,
              ],
              stops: const [0.0, 1.0],
            ).createShader(
              Rect.fromCenter(
                center: Offset(
                  _trailPositions[i].x - position.x,
                  _trailPositions[i].y - position.y,
                ),
                width: trailSize * 2,
                height: trailSize * 2,
              ),
            )
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      canvas.drawCircle(
        Offset(
          _trailPositions[i].x - position.x,
          _trailPositions[i].y - position.y,
        ),
        trailSize,
        trailPaint,
      );
    }
  }

  void _drawBulletCore(Canvas canvas) {
    // Main bullet body with metallic gradient
    final corePaint =
        Paint()
          ..shader = LinearGradient(
            colors: const [
              Color(0xFFFFFFFF), // White core
              Color(0xFF00FFFF), // Cyan
              Color(0xFF0080FF), // Blue
              Color(0xFF4040FF), // Deep blue
            ],
            stops: const [0.0, 0.3, 0.7, 1.0],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(
            Rect.fromLTWH(-size.x / 2, -size.y / 2, size.x, size.y),
          );

    // Draw elongated hexagonal bullet shape
    final path = Path();
    final halfWidth = size.x / 2;
    final halfHeight = size.y / 2;

    // Create a pointed bullet shape
    path.moveTo(0, -halfHeight); // Top point
    path.lineTo(halfWidth * 0.7, -halfHeight * 0.7);
    path.lineTo(halfWidth, -halfHeight * 0.2);
    path.lineTo(halfWidth, halfHeight * 0.8);
    path.lineTo(halfWidth * 0.3, halfHeight);
    path.lineTo(-halfWidth * 0.3, halfHeight);
    path.lineTo(-halfWidth, halfHeight * 0.8);
    path.lineTo(-halfWidth, -halfHeight * 0.2);
    path.lineTo(-halfWidth * 0.7, -halfHeight * 0.7);
    path.close();

    canvas.drawPath(path, corePaint);
  }

  void _drawBulletGlow(Canvas canvas) {
    // Outer glow effect
    final glowPaint =
        Paint()
          ..shader = RadialGradient(
            colors: [
              Color(0xFF00FFFF).withOpacity(0.8 * _glowIntensity),
              Color(0xFF0080FF).withOpacity(0.4 * _glowIntensity),
              Colors.transparent,
            ],
            stops: const [0.0, 0.6, 1.0],
          ).createShader(
            Rect.fromCenter(
              center: Offset.zero,
              width: size.x * 3,
              height: size.y * 2,
            ),
          )
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 * _glowIntensity);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: size.x * 2.5,
        height: size.y * 1.5,
      ),
      glowPaint,
    );

    // Inner bright core
    final innerGlowPaint =
        Paint()
          ..shader = RadialGradient(
            colors: [
              Color(0xFFFFFFFF).withOpacity(0.9),
              Color(0xFF00FFFF).withOpacity(0.6),
              Colors.transparent,
            ],
            stops: const [0.0, 0.4, 1.0],
          ).createShader(
            Rect.fromCenter(center: Offset.zero, width: size.x, height: size.y),
          )
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: size.x * 0.8,
        height: size.y * 0.6,
      ),
      innerGlowPaint,
    );
  }

  void _drawSparkles(Canvas canvas) {
    // Draw animated sparkles around the bullet
    final sparklePaint =
        Paint()
          ..color = Colors.white.withOpacity(0.8)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);

    for (int i = 0; i < 6; i++) {
      final angle = (_sparkleRotation + (i * math.pi / 3)) % (2 * math.pi);
      final distance = size.x * (1.2 + math.sin(_trailOffset + i) * 0.3);
      final sparkleX = math.cos(angle) * distance;
      final sparkleY = math.sin(angle) * distance;

      final sparkleSize = 1.5 + math.sin(_trailOffset * 2 + i) * 0.5;

      // Draw cross-shaped sparkle
      canvas.drawLine(
        Offset(sparkleX - sparkleSize, sparkleY),
        Offset(sparkleX + sparkleSize, sparkleY),
        sparklePaint,
      );
      canvas.drawLine(
        Offset(sparkleX, sparkleY - sparkleSize),
        Offset(sparkleX, sparkleY + sparkleSize),
        sparklePaint,
      );
    }
  }

  @override
  void update(double dt) {
    if (isActive) {
      position.y -= speed * dt;

      // Update trail positions
      for (int i = _trailPositions.length - 1; i > 0; i--) {
        _trailPositions[i] = Vector2.copy(_trailPositions[i - 1]);
      }
      _trailPositions[0] = Vector2.copy(position);

      // Animate glow intensity
      _glowIntensity = 0.8 + math.sin(_trailOffset * 8) * 0.2;

      // Update animation offsets
      _trailOffset += dt * 12;
      _sparkleRotation += dt * 3;
    }
    super.update(dt);
  }

  Rect toRect() => Rect.fromLTWH(
    position.x - size.x / 2,
    position.y - size.y / 2,
    size.x,
    size.y,
  );
}
