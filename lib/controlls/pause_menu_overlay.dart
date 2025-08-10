// Pause Menu Overlay
import 'package:flame_game/controlls/main_menu.dart';
import 'package:flame_game/shooter_game.dart';
import 'package:flutter/material.dart';

class PauseMenuOverlay extends StatelessWidget {
  final ShooterGame game;

  const PauseMenuOverlay({Key? key, required this.game}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black.withOpacity(0.8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'GAME PAUSED',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(color: Colors.yellow.withOpacity(0.8), blurRadius: 15),
              ],
            ),
          ),

          const SizedBox(height: 40),

          MenuButton(
            text: 'RESUME',
            onPressed: () => game.resumeGame(),
            color: Colors.green,
          ),

          const SizedBox(height: 20),

          MenuButton(
            text: 'RESTART',
            onPressed: () => game.restartGame(),
            color: Colors.orange,
          ),

          const SizedBox(height: 20),

          MenuButton(
            text: 'MAIN MENU',
            onPressed: () => game.backToMainMenu(),
            color: Colors.red,
          ),
        ],
      ),
    );
  }
}
