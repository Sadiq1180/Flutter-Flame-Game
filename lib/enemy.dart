import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class Enemy extends TextComponent with HasGameRef {
  static const double speed = 150.0;
  final double _pulsateSpeed = 3.0;
  double _pulsateTime = 0.0;
  final double _rotationSpeed = 0.5; // radians per second

  late TextStyle _baseStyle;
  late IconData _iconData;
  late double _size;
  late Color _color;

  Enemy({
    required IconData iconData,
    Vector2? position,
    double size = 250, // Increased default size from 150 to 250
    Color color = Colors.yellow,
  }) : _iconData = iconData,
       _size = size,
       _color = color,
       super(
         text: String.fromCharCode(iconData.codePoint),
         position: position ?? Vector2.zero(),
         anchor: Anchor.center,
       ) {
    _baseStyle = TextStyle(
      fontFamily: iconData.fontFamily,
      package: iconData.fontPackage,
      fontSize: _size,
      color: _color,
      shadows: [
        Shadow(
          color: Colors.redAccent.withOpacity(0.7),
          blurRadius: 12,
          offset: Offset.zero,
        ),
        Shadow(
          color: Colors.orangeAccent.withOpacity(0.5),
          blurRadius: 24,
          offset: Offset.zero,
        ),
      ],
    );
    textRenderer = TextPaint(style: _baseStyle);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Move enemy downwards
    position.y += speed * dt;

    // Update pulsate animation
    _pulsateTime += dt;
    final glowIntensity =
        0.6 + 0.4 * (sin(_pulsateTime * _pulsateSpeed) + 1) / 2;

    // Create a new style with pulsating shadow opacity
    final animatedStyle = _baseStyle.copyWith(
      shadows: [
        Shadow(
          color: Colors.redAccent.withOpacity(glowIntensity),
          blurRadius: 12,
          offset: Offset.zero,
        ),
        Shadow(
          color: Colors.orangeAccent.withOpacity(glowIntensity * 0.7),
          blurRadius: 24,
          offset: Offset.zero,
        ),
      ],
    );

    // Update the textRenderer with new style
    textRenderer = TextPaint(style: animatedStyle);

    // Slowly rotate the enemy for a dynamic effect
    angle += _rotationSpeed * dt;
  }
}
