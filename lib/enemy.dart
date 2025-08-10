import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';

class Enemy extends TextComponent with HasGameRef {
  // Movement/animation
  static const double fallSpeed = 150.0;
  final double _rotationSpeed = 0.6; // radians/sec
  final double _wobbleAmp = 0.15; // radians
  final double _wobbleSpeed = 2.0; // Hz
  final double _scalePulseAmp = 0.08;
  final double _scalePulseSpeed = 2.5; // Hz
  final double _hueCycleSpeed = 24.0; // degrees/sec
  final Random _rng = Random();

  // Visuals
  final double _size;
  final IconData _iconData;
  Color _baseColor;
  late final double _haloRadius;
  late final double _baseX;

  // Time/state
  double _t = 0.0;
  double _trailTimer = 0.0;

  // Painters
  late TextPaint _fillPaint;
  late TextPaint _strokePaint;

  // Child glow
  late final _GlowHalo _halo;

  Enemy({
    required IconData iconData,
    Vector2? position,
    double size = 250,
    Color color = Colors.yellow,
  }) : _iconData = iconData,
       _size = size,
       _baseColor = color,
       super(
         text: String.fromCharCode(iconData.codePoint),
         position: position ?? Vector2.zero(),
         anchor: Anchor.center,
       ) {
    _haloRadius = size * 0.55;
    _baseX = (position ?? Vector2.zero()).x;

    // Initialize paints; will update every frame for animation.
    _fillPaint = TextPaint(
      style: TextStyle(
        fontFamily: iconData.fontFamily,
        package: iconData.fontPackage,
        fontSize: _size,
        // color is handled by foreground shader
        shadows: const [], // handled via glow + stroke for sharper look
      ),
    );

    _strokePaint = TextPaint(
      style: TextStyle(
        fontFamily: iconData.fontFamily,
        package: iconData.fontPackage,
        fontSize: _size,
        // Outline via stroke paint
        foreground:
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = max(2.0, _size * 0.03)
              ..color = Colors.black.withOpacity(0.65),
      ),
    );
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Soft glow behind the glyph
    _halo =
        _GlowHalo(radius: _haloRadius, baseColor: _baseColor, intensity: 0.8)
          ..position = Vector2.zero()
          ..anchor = Anchor.center
          ..priority = -1;
    add(_halo);

    // Ensure the text is centered nicely
    anchor = Anchor.center;
    textRenderer = _fillPaint;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;

    // Fall
    position.y += fallSpeed * dt;

    // Horizontal sway around the spawn X
    position.x = _baseX + sin(_t * _wobbleSpeed) * (_size * 0.12);

    // Rotation with gentle wobble
    angle = _rotationSpeed * _t + sin(_t * _wobbleSpeed * 0.8) * _wobbleAmp;

    // Scale pulsation
    final s = 1.0 + _scalePulseAmp * sin(_t * _scalePulseSpeed * 2 * pi);
    scale.setValues(s, s);

    // Animate hue, gradient, and halo
    _updateGradientFill();
    _halo
      ..intensity = 0.6 + 0.4 * (0.5 + 0.5 * sin(_t * 3.0))
      ..baseColor = _animatedColor();

    // Particle trail
    _trailTimer += dt;
    if (_trailTimer >= 0.05) {
      _trailTimer = 0.0;
      _spawnTrail();
    }
  }

  @override
  void render(Canvas canvas) {
    // Draw outline first for crisp edges
    _strokePaint.render(canvas, text, Vector2.zero(), anchor: Anchor.center);
    // Fill on top
    _fillPaint.render(canvas, text, Vector2.zero(), anchor: Anchor.center);
  }

  // --- Helpers -------------------------------------------------------------

  // Smoothly cycle the base color’s hue over time
  Color _animatedColor() {
    final hsv = HSVColor.fromColor(_baseColor);
    final hue = (hsv.hue + _hueCycleSpeed * _t) % 360.0;
    return hsv.withHue(hue).toColor();
  }

  /// enemie hit sound effecet
  void onHit() {
    FlameAudio.play('assets/enemy_hit/enemie_hit_1.wav', volume: 0.9);
  }

  // Update fill gradient and subtle shadow via shader each frame
  void _updateGradientFill() {
    final c = _animatedColor();
    final highlight = Colors.white.withOpacity(0.9);
    final deep = HSLColor.fromColor(c).withLightness(0.35).toColor();

    final rect = Rect.fromLTWH(-_size * 0.5, -_size * 0.5, _size, _size);
    final shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [highlight, c, deep],
      stops: const [0.05, 0.45, 1.0],
    ).createShader(rect);

    _fillPaint = TextPaint(
      style: TextStyle(
        fontFamily: _iconData.fontFamily,
        package: _iconData.fontPackage,
        fontSize: _size,
        foreground: Paint()..shader = shader,
        // Soft glint using layered shadows
        shadows: [
          Shadow(
            color: c.withOpacity(0.35),
            blurRadius: _size * 0.06,
            offset: Offset.zero,
          ),
          Shadow(
            color: c.withOpacity(0.15),
            blurRadius: _size * 0.16,
            offset: Offset.zero,
          ),
        ],
      ),
    );

    // Keep stroke thickness in sync with scale for stable look
    _strokePaint = TextPaint(
      style: TextStyle(
        fontFamily: _iconData.fontFamily,
        package: _iconData.fontPackage,
        fontSize: _size,
        foreground:
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = max(2.0, _size * 0.03) / max(0.8, scale.x)
              ..color = Colors.black.withOpacity(0.65),
      ),
    );
  }

  void _spawnTrail() {
    final sparkleColor = _animatedColor().withOpacity(0.9);

    add(
      ParticleSystemComponent(
        position: Vector2(0, _size * 0.35),
        anchor: Anchor.center,
        priority: -2,
        particle: Particle.generate(
          count: 8,
          lifespan: 0.35,
          generator: (i) {
            final dir =
                (Vector2.random(_rng) - Vector2.random(_rng))..normalize();
            final speed = 20 + _rng.nextDouble() * 35;

            return AcceleratedParticle(
              // Drift downward slightly
              acceleration: Vector2(0, 180),
              speed: dir * speed,
              child: CircleParticle(
                radius: 1.6 + _rng.nextDouble() * 1.2,
                paint:
                    Paint()
                      ..color = sparkleColor
                      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
              ),
            );
          },
        ),
      ),
    );
  }
}

// Simple radial glow component
class _GlowHalo extends PositionComponent {
  double radius;
  double intensity; // 0..1
  Color baseColor;

  _GlowHalo({
    required this.radius,
    required this.baseColor,
    this.intensity = 0.8,
  }) : super(anchor: Anchor.center);

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromCircle(center: Offset.zero, radius: radius);
    final shader = RadialGradient(
      colors: [
        baseColor.withOpacity(0.55 * intensity),
        baseColor.withOpacity(0.15 * intensity),
        Colors.transparent,
      ],
      stops: const [0.0, 0.4, 1.0],
    ).createShader(rect);

    final paint = Paint()..shader = shader;
    canvas.drawCircle(Offset.zero, radius, paint);
  }
}
