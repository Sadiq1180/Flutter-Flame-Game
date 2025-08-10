// Main Menu Overlay
import 'package:flame_game/controlls/main_menu.dart';
import 'package:flame_game/shooter_game.dart';
import 'package:flutter/material.dart';

class MainMenuOverlay extends StatelessWidget {
  final ShooterGame game;

  const MainMenuOverlay({Key? key, required this.game}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withOpacity(0.8),
            Colors.blue.withOpacity(0.3),
            Colors.purple.withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Game Title
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  'SPACE',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.cyan.withOpacity(0.8),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                ),
                Text(
                  'SHOOTER',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.cyan.withOpacity(0.8),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Defend Earth from alien invasion!',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.8),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 60),

          // Start Button
          MenuButton(
            text: 'START GAME',
            onPressed: () => game.startGame(),
            color: Colors.green,
          ),

          const SizedBox(height: 20),

          // Instructions
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.symmetric(horizontal: 40),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.cyan.withOpacity(0.3), width: 1),
            ),
            child: Column(
              children: [
                Text(
                  'HOW TO PLAY',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.cyan,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '• Use left/right buttons to move\n'
                  '• Ship automatically shoots bullets\n'
                  '• Destroy enemies to earn points\n'
                  '• Avoid enemy collisions\n'
                  '• Survive as long as possible!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                  textAlign: TextAlign.left,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
