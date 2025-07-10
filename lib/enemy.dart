import 'dart:ui';

import 'package:flame/components.dart';

class Enemy extends RectangleComponent {
  static const double speed = 150.0;

  Enemy({super.position}) : super(size: Vector2(30, 30));

  @override
  Future<void> onLoad() async {
    paint = Paint()..color = const Color(0xFFFF0000);
  }

  @override
  void update(double dt) {
    position.y += speed * dt;
    super.update(dt);
  }

  Rect toRect() => Rect.fromLTWH(position.x, position.y, size.x, size.y);
}
