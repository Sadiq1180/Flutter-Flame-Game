// main_game.dart (ShooterGame Screen Only)

import 'dart:math';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'player.dart';
import 'enemy.dart';
import 'bullet.dart';

class ShooterGame extends FlameGame with TapDetector {
  late Player player;
  late TextComponent scoreText;
  late TextComponent healthText;

  final Random _random = Random();
  double enemySpawnTimer = 0;
  double spawnInterval = 2.0;

  double bulletTimer = 0;
  final double bulletInterval = 0.3;

  int score = 0;
  int health = 3;
  bool gameOver = false;

  final List<Bullet> _activeBullets = [];
  final List<Enemy> _activeEnemies = [];

  @override
  Future<void> onLoad() async {
    player = Player();
    await add(player);

    scoreText = TextComponent(
      text: 'Score: 0',
      position: Vector2(10, 10),
      anchor: Anchor.topLeft,
      priority: 100,
    );
    await add(scoreText);

    healthText = TextComponent(
      text: 'Lives: 3',
      position: Vector2(10, 40),
      anchor: Anchor.topLeft,
      priority: 100,
    );
    await add(healthText);
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

    scoreText.text = 'Score: $score';
    healthText.text = 'Lives: $health';
  }

  void _updateActiveLists() {
    _activeBullets.clear();
    _activeEnemies.clear();
    for (final c in children) {
      if (c is Bullet) _activeBullets.add(c);
      if (c is Enemy) _activeEnemies.add(c);
    }
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
          break;
        }
      }
    }

    for (final enemy in _activeEnemies) {
      if (player.toRect().overlaps(enemy.toRect())) {
        enemiesToRemove.add(enemy);
        health--;
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
      )..isActive = true;
      add(bullet);
    }
  }

  void spawnEnemy() {
    final x = _random.nextDouble() * (size.x - 30);
    final enemy = Enemy(position: Vector2(x, -30));
    add(enemy);
  }

  void _showGameOver() {
    add(
      TextComponent(
        text: 'Game Over! Score: $score',
        position: size / 2,
        anchor: Anchor.center,
        priority: 200,
      ),
    );
  }

  void restartGame() {
    children.whereType<Bullet>().forEach((b) => b.removeFromParent());
    children.whereType<Enemy>().forEach((e) => e.removeFromParent());
    children
        .whereType<TextComponent>()
        .where((t) => t.text.contains('Game Over'))
        .forEach((t) => t.removeFromParent());
    score = 0;
    health = 3;
    gameOver = false;
    spawnInterval = 2.0;
    bulletTimer = 0;
    enemySpawnTimer = 0;
  }

  void movePlayerLeft() {
    if (!gameOver) player.position.x = max(0, player.position.x - 50);
  }

  void movePlayerRight() {
    if (!gameOver)
      player.position.x = min(size.x - player.size.x, player.position.x + 50);
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
