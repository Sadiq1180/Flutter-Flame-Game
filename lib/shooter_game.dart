// shooter_game.dart
import 'dart:async';
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

enum GameState { mainMenu, playing, paused, gameOver }

class ShooterGame extends FlameGame with TapDetector {
  late Player player;
  late GameUI gameUI;

  final StreamController<GameState> _gameStateController =
      StreamController<GameState>.broadcast();
  Stream<GameState> get gameStateStream => _gameStateController.stream;

  final Random _random = Random();
  double enemySpawnTimer = 0;
  double spawnInterval = 2.0;

  double bulletTimer = 0;
  final double bulletInterval = 0.3;

  int score = 0;
  int health = 5;
  GameState gameState = GameState.mainMenu;
  double playerSpeed = 300.0;

  // Player movement state
  bool isMovingLeft = false;
  bool isMovingRight = false;

  final List<Bullet> _activeBullets = [];
  final List<Enemy> _activeEnemies = [];

  @override
  Future<void> onLoad() async {
    player = Player();
    await add(player);

    gameUI = GameUI();
    await add(gameUI);

    // Show main menu initially
    _showMainMenu();
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (gameState != GameState.playing) return;

    // Handle smooth player movement
    _updatePlayerMovement(dt);

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
      gameState = GameState.gameOver;
      _showGameOver();
    }

    // Update UI
    gameUI.updateScore(score);
    gameUI.updateHealth(health);
    gameUI.updateGameState(gameState);
  }

  void _updatePlayerMovement(double dt) {
    if (isMovingLeft && !isMovingRight) {
      player.position.x = max(0, player.position.x - playerSpeed * dt);
    } else if (isMovingRight && !isMovingLeft) {
      player.position.x = min(
        size.x - player.size.x,
        player.position.x + playerSpeed * dt,
      );
    }
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
          gameUI.triggerScoreEffect();
          break;
        }
      }
    }

    for (final enemy in _activeEnemies) {
      if (player.toRect().overlaps(enemy.toRect())) {
        enemiesToRemove.add(enemy);
        health--;
        gameUI.triggerDamageEffect();
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

  // Menu system methods
  void _showMainMenu() {
    overlays.add('MainMenu');
  }

  void _showGameOver() {
    overlays.add('GameOverMenu');
  }

  void _showPauseMenu() {
    overlays.add('PauseMenu');
  }

  void startGame() {
    gameState = GameState.playing;
    overlays.remove('MainMenu');
  }

  void pauseGame() {
    if (gameState == GameState.playing) {
      gameState = GameState.paused;
      _showPauseMenu();
    }
  }

  void resumeGame() {
    if (gameState == GameState.paused) {
      gameState = GameState.playing;
      overlays.remove('PauseMenu');
    }
  }

  void restartGame() {
    children.whereType<Bullet>().forEach((b) => b.removeFromParent());
    children.whereType<Enemy>().forEach((e) => e.removeFromParent());

    score = 0;
    health = 5;
    gameState = GameState.playing;
    spawnInterval = 2.0;
    bulletTimer = 0;
    enemySpawnTimer = 0;
    isMovingLeft = false;
    isMovingRight = false;

    overlays.remove('GameOverMenu');
    overlays.remove('PauseMenu');
  }

  void backToMainMenu() {
    children.whereType<Bullet>().forEach((b) => b.removeFromParent());
    children.whereType<Enemy>().forEach((e) => e.removeFromParent());

    score = 0;
    health = 5;
    gameState = GameState.mainMenu;
    spawnInterval = 2.0;
    bulletTimer = 0;
    enemySpawnTimer = 0;
    isMovingLeft = false;
    isMovingRight = false;

    overlays.remove('GameOverMenu');
    overlays.remove('PauseMenu');
    _showMainMenu();
  }

  // Improved player movement methods
  void startMovingLeft() {
    if (gameState == GameState.playing) {
      isMovingLeft = true;
    }
  }

  void stopMovingLeft() {
    isMovingLeft = false;
  }

  void startMovingRight() {
    if (gameState == GameState.playing) {
      isMovingRight = true;
    }
  }

  void stopMovingRight() {
    isMovingRight = false;
  }

  @override
  void onTapDown(TapDownInfo info) {
    if (gameState == GameState.gameOver) {
      restartGame();
      return;
    }

    if (gameState != GameState.playing) return;

    final tapX = info.eventPosition.global.x;
    final playerCenter = player.position.x + player.size.x / 2;

    // For tap controls, we'll do instant movement with smaller steps
    if (tapX < playerCenter) {
      player.position.x = max(0, player.position.x - 50);
    } else {
      player.position.x = min(size.x - player.size.x, player.position.x + 50);
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
  GameState _gameState = GameState.mainMenu;

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
    priority = 100;
    _initializePaints();
  }

  void _initializePaints() {
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

    _healthBarBgPaint =
        Paint()
          ..color = const Color(0xFF333333)
          ..style = PaintingStyle.fill;
  }

  @override
  void render(Canvas canvas) {
    if (gameRef.size == Vector2.zero()) return;

    // Only show UI when playing or paused
    if (_gameState == GameState.playing || _gameState == GameState.paused) {
      canvas.save();

      _drawUIBackground(canvas);
      _drawScorePanel(canvas);
      _drawHealthPanel(canvas);
      _drawHealthBar(canvas);

      // Show pause indicator when paused
      if (_gameState == GameState.paused) {
        _drawPauseIndicator(canvas);
      }

      canvas.restore();
    }
  }

  void _drawPauseIndicator(Canvas canvas) {
    canvas.save();
    canvas.translate(gameRef.size.x / 2, 150);

    _drawText(
      canvas,
      'PAUSED',
      Offset.zero,
      const Color(0xFFFFFF00),
      32,
      FontWeight.bold,
      textAlign: TextAlign.center,
    );

    canvas.restore();
  }

  void _drawUIBackground(Canvas canvas) {
    final bgRect = Rect.fromLTWH(0, 0, gameRef.size.x, 120);
    canvas.drawRect(bgRect, _backgroundPaint);

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

  void _drawScorePanel(Canvas canvas) {
    final panelWidth = 150.0;
    final panelHeight = 45.0;
    final panelRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(20, 20, panelWidth, panelHeight),
      const Radius.circular(12),
    );

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

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(15, 15, panelWidth + 10, panelHeight + 10),
        const Radius.circular(15),
      ),
      glowPaint,
    );

    canvas.drawRRect(panelRect, _scorePanelPaint);

    final borderPaint =
        Paint()
          ..color = const Color(0xFF00FFFF).withOpacity(0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
    canvas.drawRRect(panelRect, borderPaint);

    canvas.save();
    canvas.translate(100, 42.5);
    canvas.scale(_scoreScaleAnimation);

    _drawText(
      canvas,
      'SCORE',
      const Offset(-70, -15),
      const Color(0xFF88DDFF),
      14,
      FontWeight.bold,
    );

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

  void _drawHealthPanel(Canvas canvas) {
    final panelWidth = 150.0;
    final panelHeight = 45.0;
    final panelX = gameRef.size.x - panelWidth - 20;
    final panelRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(panelX, 20, panelWidth, panelHeight),
      const Radius.circular(12),
    );

    final healthRatio = _currentHealth / 5.0;
    final isLowHealth = healthRatio <= 0.33;

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

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(panelX - 5, 15, panelWidth + 10, panelHeight + 10),
        const Radius.circular(15),
      ),
      glowPaint,
    );

    canvas.drawRRect(panelRect, _healthPanelPaint);

    final borderPaint =
        Paint()
          ..color = (isLowHealth
                  ? const Color(0xFFFF4444)
                  : const Color(0xFF44FF44))
              .withOpacity(0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
    canvas.drawRRect(panelRect, borderPaint);

    canvas.save();
    canvas.translate(panelX + panelWidth / 2, 42.5);

    if (_damageFlashAnimation > 0) {
      canvas.scale(1.0 + _damageFlashAnimation * 0.1);
    }

    _drawText(
      canvas,
      'LIVES',
      const Offset(-70, -15),
      isLowHealth ? const Color(0xFFFF8888) : const Color(0xFF88FF88),
      14,
      FontWeight.bold,
    );

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

  void _drawHealthBar(Canvas canvas) {
    final barWidth = 150.0;
    final barHeight = 15.0;
    final barX = gameRef.size.x - 150 - 20;
    final barY = 80.0;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barX, barY, barWidth, barHeight),
        const Radius.circular(4),
      ),
      _healthBarBgPaint,
    );

    final healthRatio = _currentHealth / 5.0;
    final fillWidth = barWidth * healthRatio;

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

    if (_scoreEffectTimer > 0) {
      _scoreEffectTimer -= dt;
      _scoreScaleAnimation = 1.0 + (1.0 - _scoreEffectTimer / 0.3) * 0.2;
      _scoreGlowAnimation += dt * 15;

      if (_scoreEffectTimer <= 0) {
        _scoreScaleAnimation = 1.0;
        _scoreGlowAnimation = 0.0;
      }
    }

    if (_damageEffectTimer > 0) {
      _damageEffectTimer -= dt;
      _damageFlashAnimation = _damageEffectTimer / 0.2;

      if (_damageEffectTimer <= 0) {
        _damageFlashAnimation = 0.0;
      }
    }

    _healthPulseAnimation += dt;
  }

  void updateScore(int score) {
    _currentScore = score;
  }

  void updateHealth(int health) {
    _currentHealth = health;
  }

  void updateGameState(GameState gameState) {
    _gameState = gameState;
  }

  void triggerScoreEffect() {
    _scoreEffectTimer = 0.3;
  }

  void triggerDamageEffect() {
    _damageEffectTimer = 0.2;
  }
}
