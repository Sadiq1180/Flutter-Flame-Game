import 'dart:ui';

import 'package:flame/components.dart';

class Bullet extends RectangleComponent {
  bool isActive = false;
  static const double speed = 400.0;

  Bullet({super.position}) : super(size: Vector2(5, 10));

  @override
  Future<void> onLoad() async {
    paint = Paint()..color = const Color(0xFFFFFF00);
  }

  @override
  void update(double dt) {
    if (isActive) {
      position.y -= speed * dt;
    }
    super.update(dt);
  }

  Rect toRect() => Rect.fromLTWH(position.x, position.y, size.x, size.y);
}
