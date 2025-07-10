import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';

class Player extends PositionComponent with HasGameRef<FlameGame> {
  final double moveSpeed = 200;
  late Paint _paint;

  Player();

  @override
  Future<void> onLoad() async {
    size = Vector2(50, 50);
    _paint = Paint()..color = const Color(0xFF00FF00);
  }

  @override
  void onMount() {
    super.onMount();
    position = Vector2(
      (gameRef.size.x - size.x) / 2,
      gameRef.size.y - size.y - 20,
    );
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(size.toRect(), _paint);
  }

  Rect toRect() => Rect.fromLTWH(position.x, position.y, size.x, size.y);
}
