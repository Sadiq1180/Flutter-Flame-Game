// shooter_game.dart
import 'dart:math';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'player.dart';
import 'enemy.dart';
import 'bullet.dart';

class ShooterGame extends FlameGame with TapDetector {
  late Player player;
  late GameUI gameUI;

  final Random _random = Random();
  double enemySpawnTimer = 0;
  double spawnInterval = 2.0;

  double bulletTimer = 0;
  final double bulletInterval = 0.3;

  int score = 0;
  int health = 5;
  bool gameOver = false;

  final List<Bullet> _activeBullets = [];
  final List<Enemy> _activeEnemies = [];

  @override
  Future<void> onLoad() async {
    player = Player();
    await add(player);

    gameUI = GameUI();
    await add(gameUI);
  }

  @override
  void update(double dt) {
    if (gameOver) return;
    super.update(dt);

    bulletTimer += dt;
    if (bulletTimer >= bulletInterval) {
      shootBullet();
      bulletTimer = 0;
    }

    enemySpawnTimer += dt;
    if (enemySpawnTimer >= spawnInterval) {
      spawnEnemy();
      enemySpawnTimer = 0;
      if (spawnInterval > 0.5) {
        spawnInterval = max(0.5, spawnInterval - 0.01);
      }
    }

    _updateActiveLists();
    _checkCollisions();
    _removeOffScreenObjects();

    if (health <= 0) {
      gameOver = true;
      _showGameOver();
    }

    // Update UI
    gameUI.updateScore(score);
    gameUI.updateHealth(health);
    gameUI.updateGameState(gameOver);
  }

  void _updateActiveLists() {
    _activeBullets
      ..clear()
      ..addAll(children.whereType<Bullet>());
    _activeEnemies
      ..clear()
      ..addAll(children.whereType<Enemy>());
  }

  void _checkCollisions() {
    final bulletsToRemove = <Bullet>[];
    final enemiesToRemove = <Enemy>[];

    for (final bullet in _activeBullets) {
      for (final enemy in _activeEnemies) {
        if (bullet.toRect().overlaps(enemy.toRect())) {
          bulletsToRemove.add(bullet);
          enemiesToRemove.add(enemy);
          score += 10;
          gameUI.triggerScoreEffect(); // Trigger score animation
          break;
        }
      }
    }

    for (final enemy in _activeEnemies) {
      if (player.toRect().overlaps(enemy.toRect())) {
        enemiesToRemove.add(enemy);
        health--;
        gameUI.triggerDamageEffect(); // Trigger damage animation
        break;
      }
    }

    for (final b in bulletsToRemove) b.removeFromParent();
    for (final e in enemiesToRemove) e.removeFromParent();
  }

  void _removeOffScreenObjects() {
    final bulletsToRemove =
        _activeBullets.where((b) => b.position.y < -50).toList();
    final enemiesToRemove =
        _activeEnemies.where((e) => e.position.y > size.y + 50).toList();
    health -= enemiesToRemove.length;
    if (enemiesToRemove.isNotEmpty) {
      gameUI.triggerDamageEffect();
    }
    for (final b in bulletsToRemove) b.removeFromParent();
    for (final e in enemiesToRemove) e.removeFromParent();
  }

  void shootBullet() {
    if (_activeBullets.length < 10) {
      final bullet = Bullet(
        position: Vector2(
          player.position.x + player.size.x / 2 - 2.5,
          player.position.y - 20,
        ),
        iconData: Icons.arrow_drop_up,
      )..isActive = true;
      add(bullet);
    }
  }

  void spawnEnemy() {
    final x = _random.nextDouble() * (size.x - 30);
    final enemy = Enemy(
      position: Vector2(x, -30),
      iconData: Icons.android,
      size: 30,
    );
    add(enemy);
  }

  void _showGameOver() {
    overlays.add('GameOverMenu');
  }

  void restartGame() {
    children.whereType<Bullet>().forEach((b) => b.removeFromParent());
    children.whereType<Enemy>().forEach((e) => e.removeFromParent());

    score = 0;
    health = 5;
    gameOver = false;
    spawnInterval = 2.0;
    bulletTimer = 0;
    enemySpawnTimer = 0;

    overlays.remove('GameOverMenu');
  }

  void movePlayerLeft() {
    if (!gameOver) player.position.x = max(0, player.position.x - 50);
  }

  void movePlayerRight() {
    if (!gameOver) {
      player.position.x = min(size.x - player.size.x, player.position.x + 50);
    }
  }

  @override
  void onTapDown(TapDownInfo info) {
    if (gameOver) {
      restartGame();
      return;
    }
    final tapX = info.eventPosition.global.x;
    final playerCenter = player.position.x + player.size.x / 2;
    if (tapX < playerCenter) {
      movePlayerLeft();
    } else {
      movePlayerRight();
    }
  }
}

class GameUI extends PositionComponent with HasGameRef<FlameGame> {
  late Paint _backgroundPaint;
  late Paint _scorePanelPaint;
  late Paint _healthPanelPaint;
  late Paint _healthBarPaint;
  late Paint _healthBarBgPaint;

  int _currentScore = 0;
  int _currentHealth = 3;
  bool _gameOver = false;

  // Animation properties
  double _scoreScaleAnimation = 1.0;
  double _scoreGlowAnimation = 0.0;
  double _damageFlashAnimation = 0.0;
  double _healthPulseAnimation = 0.0;
  double _uiTime = 0.0;

  // Effect timers
  double _scoreEffectTimer = 0.0;
  double _damageEffectTimer = 0.0;

  @override
  Future<void> onLoad() async {
    priority = 100; // Ensure UI renders on top
    _initializePaints();
  }

  void _initializePaints() {
    // Semi-transparent background for UI panels
    _backgroundPaint =
        Paint()
          ..shader = LinearGradient(
            colors: [
              Colors.black.withOpacity(0.7),
              Colors.black.withOpacity(0.3),
              Colors.transparent,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(Rect.fromLTWH(0, 0, 400, 100))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    // Score panel with cyan glow
    _scorePanelPaint =
        Paint()
          ..shader = LinearGradient(
            colors: const [
              Color(0xFF001122),
              Color(0xFF003344),
              Color(0xFF004466),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(Rect.fromLTWH(0, 0, 200, 50))
          ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 2);

    // Health panel with red glow when low
    _healthPanelPaint =
        Paint()
          ..shader = LinearGradient(
            colors: const [
              Color(0xFF220011),
              Color(0xFF440033),
              Color(0xFF660044),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(Rect.fromLTWH(0, 0, 200, 50))
          ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 2);

    // Health bar
    _healthBarPaint =
        Paint()
          ..shader = LinearGradient(
            colors: const [
              Color(0xFF00FF88),
              Color(0xFF00DD66),
              Color(0xFF00BB44),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ).createShader(Rect.fromLTWH(0, 0, 150, 8));

    // Health bar background
    _healthBarBgPaint =
        Paint()
          ..color = const Color(0xFF333333)
          ..style = PaintingStyle.fill;
  }

  @override
  void render(Canvas canvas) {
    if (gameRef.size == Vector2.zero()) return;

    canvas.save();

    // Draw top UI background gradient
    _drawUIBackground(canvas);

    // Draw score panel
    _drawScorePanel(canvas);

    // Draw health panel
    _drawHealthPanel(canvas);

    // Draw health bar
    _drawHealthBar(canvas);

    // Draw game over overlay if needed
    if (_gameOver) {
      _drawGameOverOverlay(
        canvas,
      ); /////////////////////////////////////////////////
    }

    canvas.restore();
  }

  ///score ui
  void _drawUIBackground(Canvas canvas) {
    final bgRect = Rect.fromLTWH(0, 0, gameRef.size.x, 120);
    canvas.drawRect(bgRect, _backgroundPaint);

    // Add subtle scan lines effect
    final scanLinePaint =
        Paint()
          ..color = const Color(0xFF00FFFF).withOpacity(0.1)
          ..strokeWidth = 1;

    for (int i = 0; i < 140; i += 4) {
      final opacity = (math.sin(_uiTime * 3 + i * 0.1) + 1) * 0.05;
      scanLinePaint.color = Color(0xFF00FFFF).withOpacity(opacity);
      canvas.drawLine(
        Offset(0, i.toDouble()),
        Offset(gameRef.size.x, i.toDouble()),
        scanLinePaint,
      );
    }
  }

  //this is score panel
  void _drawScorePanel(Canvas canvas) {
    final panelWidth = 150.0;
    final panelHeight = 45.0;
    final panelRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(20, 20, panelWidth, panelHeight),
      const Radius.circular(12),
    );

    // Animate panel glow based on score changes
    final glowIntensity = 0.5 + math.sin(_scoreGlowAnimation * 8) * 0.3;
    final glowPaint =
        Paint()
          ..shader = RadialGradient(
            colors: [
              Color(0xFF00FFFF).withOpacity(glowIntensity * 0.6),
              Color(0xFF0080FF).withOpacity(glowIntensity * 0.3),
              Colors.transparent,
            ],
          ).createShader(Rect.fromLTWH(20, 20, panelWidth, panelHeight))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    // Draw glow
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(15, 15, panelWidth + 10, panelHeight + 10),
        const Radius.circular(15),
      ),
      glowPaint,
    );

    // Draw panel background
    canvas.drawRRect(panelRect, _scorePanelPaint);

    // Draw border
    final borderPaint =
        Paint()
          ..color = const Color(0xFF00FFFF).withOpacity(0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
    canvas.drawRRect(panelRect, borderPaint);

    // Draw score text with scale animation
    canvas.save();
    canvas.translate(100, 42.5);
    canvas.scale(_scoreScaleAnimation);

    // Score label
    _drawText(
      canvas,
      'SCORE',
      const Offset(-70, -15),
      const Color(0xFF88DDFF),
      14,
      FontWeight.bold,
    );

    // Score value
    _drawText(
      canvas,
      _formatScore(_currentScore),
      const Offset(-70, 5),
      const Color(0xFFFFFFFF),
      18,
      FontWeight.w900,
    );

    canvas.restore();
  }

  ////this is health panel
  void _drawHealthPanel(Canvas canvas) {
    final panelWidth = 150.0;
    final panelHeight = 45.0;
    final panelX = gameRef.size.x - panelWidth - 20;
    final panelRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(panelX, 20, panelWidth, panelHeight),
      const Radius.circular(12),
    );

    // Health-based color intensity
    final healthRatio = _currentHealth / 3.0;
    final isLowHealth = healthRatio <= 0.33;

    // Pulsing red effect when health is low
    double pulseIntensity = 0.5;
    if (isLowHealth) {
      pulseIntensity += math.sin(_healthPulseAnimation * 10) * 0.4;
    }

    final glowColor =
        isLowHealth ? const Color(0xFFFF4444) : const Color(0xFF44FF44);
    final glowPaint =
        Paint()
          ..shader = RadialGradient(
            colors: [
              glowColor.withOpacity(pulseIntensity * 0.6),
              glowColor.withOpacity(pulseIntensity * 0.3),
              Colors.transparent,
            ],
          ).createShader(Rect.fromLTWH(panelX, 20, panelWidth, panelHeight))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    // Draw glow
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(panelX - 5, 15, panelWidth + 10, panelHeight + 10),
        const Radius.circular(15),
      ),
      glowPaint,
    );

    // Draw panel background
    canvas.drawRRect(panelRect, _healthPanelPaint);

    // Draw border with health-based color
    final borderPaint =
        Paint()
          ..color = (isLowHealth
                  ? const Color(0xFFFF4444)
                  : const Color(0xFF44FF44))
              .withOpacity(0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
    canvas.drawRRect(panelRect, borderPaint);

    // Draw health text
    canvas.save();
    canvas.translate(panelX + panelWidth / 2, 42.5);

    // Add damage flash effect
    if (_damageFlashAnimation > 0) {
      canvas.scale(1.0 + _damageFlashAnimation * 0.1);
    }

    // Health label
    _drawText(
      canvas,
      'LIVES',
      const Offset(-70, -15),
      isLowHealth ? const Color(0xFFFF8888) : const Color(0xFF88FF88),
      14,
      FontWeight.bold,
    );

    // Health value
    _drawText(
      canvas,
      '${_currentHealth}/5',
      const Offset(-70, 5),
      Colors.white,
      18,
      FontWeight.w900,
    );

    canvas.restore();
  }

  ///// Health
  void _drawHealthBar(Canvas canvas) {
    final barWidth = 150.0;
    final barHeight = 15.0;
    final barX = gameRef.size.x - 150 - 20; // Align with health panel
    final barY = 80.0; // Move down to avoid overlap

    // Background
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barX, barY, barWidth, barHeight),
        const Radius.circular(4),
      ),
      _healthBarBgPaint,
    );

    // Health fill
    final healthRatio = _currentHealth / 5.0;
    final fillWidth = barWidth * healthRatio;

    // Color changes based on health
    Color healthColor;
    if (healthRatio > 0.66) {
      healthColor = const Color(0xFF00FF88);
    } else if (healthRatio > 0.33) {
      healthColor = const Color(0xFFFFAA00);
    } else {
      healthColor = const Color(0xFFFF4444);
    }

    final healthFillPaint =
        Paint()
          ..shader = LinearGradient(
            colors: [healthColor, healthColor.withOpacity(0.7)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ).createShader(Rect.fromLTWH(barX, barY, fillWidth, barHeight))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    if (fillWidth > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(barX, barY, fillWidth, barHeight),
          const Radius.circular(4),
        ),
        healthFillPaint,
      );
    }

    // Health bar border
    final borderPaint =
        Paint()
          ..color = Colors.white.withOpacity(0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barX, barY, barWidth, barHeight),
        const Radius.circular(4),
      ),
      borderPaint,
    );
  }

  void _drawGameOverOverlay(Canvas canvas) {
    // Semi-transparent overlay
    final overlayPaint = Paint()..color = Colors.black.withOpacity(0.8);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, gameRef.size.x, gameRef.size.y),
      overlayPaint,
    );

    // Game Over text with glow effect
    canvas.save();
    canvas.translate(gameRef.size.x / 2, gameRef.size.y / 2 - 50);

    final glowPaint =
        Paint()
          ..color = const Color(0xFFFF4444)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    _drawText(
      canvas,
      'GAME OVER',
      Offset.zero,
      Colors.white,
      48,
      FontWeight.w900,
      textAlign: TextAlign.center,
      glowPaint: glowPaint,
    );

    _drawText(
      canvas,
      'Final Score: ${_formatScore(_currentScore)}',
      const Offset(0, 50),
      const Color(0xFF88DDFF),
      24,
      FontWeight.bold,
      textAlign: TextAlign.center,
    );

    _drawText(
      canvas,
      'Tap to restart',
      const Offset(0, 100),
      Colors.white.withOpacity(0.7),
      18,
      FontWeight.normal,
      textAlign: TextAlign.center,
    );

    canvas.restore();
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset,
    Color color,
    double fontSize,
    FontWeight fontWeight, {
    TextAlign textAlign = TextAlign.left,
    Paint? glowPaint,
  }) {
    final textStyle = TextStyle(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontFamily: 'monospace',
    );

    final textPainter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: TextDirection.ltr,
      textAlign: textAlign,
    );

    textPainter.layout();

    final textOffset = Offset(
      offset.dx - (textAlign == TextAlign.center ? textPainter.width / 2 : 0),
      offset.dy - textPainter.height / 2,
    );

    // Draw glow effect if provided
    if (glowPaint != null) {
      textPainter.paint(canvas, textOffset);
    }

    textPainter.paint(canvas, textOffset);
  }

  String _formatScore(int score) {
    return score.toString().padLeft(6, '0');
  }

  @override
  void update(double dt) {
    super.update(dt);
    _uiTime += dt;

    // Update score effect animation
    if (_scoreEffectTimer > 0) {
      _scoreEffectTimer -= dt;
      _scoreScaleAnimation = 1.0 + (1.0 - _scoreEffectTimer / 0.3) * 0.2;
      _scoreGlowAnimation += dt * 15;

      if (_scoreEffectTimer <= 0) {
        _scoreScaleAnimation = 1.0;
        _scoreGlowAnimation = 0.0;
      }
    }

    // Update damage effect animation
    if (_damageEffectTimer > 0) {
      _damageEffectTimer -= dt;
      _damageFlashAnimation = _damageEffectTimer / 0.2;

      if (_damageEffectTimer <= 0) {
        _damageFlashAnimation = 0.0;
      }
    }

    // Update health pulse animation
    _healthPulseAnimation += dt;
  }

  void updateScore(int score) {
    _currentScore = score;
  }

  void updateHealth(int health) {
    _currentHealth = health;
  }

  void updateGameState(bool gameOver) {
    _gameOver = gameOver;
  }

  void triggerScoreEffect() {
    _scoreEffectTimer = 0.3;
  }

  void triggerDamageEffect() {
    _damageEffectTimer = 0.2;
  }
}
