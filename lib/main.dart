import 'package:flame_game/controlls/main_menu.dart';
import 'package:flame_game/controlls/main_menu_overlay.dart';
import 'package:flame_game/controlls/pause_menu_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'shooter_game.dart';
import 'game_over.dart';

void main() {
  final game = ShooterGame();

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Stack(
          children: [
            // Background
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF0A0A0A), // Dark space background
                    Color(0xFF1A1A2E), // Dark blue
                    Color(0xFF16213E), // Darker blue
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            // Game widget
            GameWidget(
              game: game,
              overlayBuilderMap: {
                'MainMenu': (context, _) => MainMenuOverlay(game: game),
                'GameOverMenu': (context, _) => GameOverPopup(game: game),
                'PauseMenu': (context, _) => PauseMenuOverlay(game: game),
              },
            ),

            // Control buttons (always show, but simplified approach)
            // Left movement button
            Positioned(
              left: 20,
              bottom: 20,
              child: GestureDetector(
                onTapDown: (_) => game.startMovingLeft(),
                onTapUp: (_) => game.stopMovingLeft(),
                onTapCancel: () => game.stopMovingLeft(),
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.cyan.withOpacity(0.3),
                        Colors.blue.withOpacity(0.2),
                        Colors.transparent,
                      ],
                    ),
                    border: Border.all(
                      color: Colors.cyan.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.arrow_circle_left_sharp,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ),

            // Right movement button
            Positioned(
              right: 20,
              bottom: 20,
              child: GestureDetector(
                onTapDown: (_) => game.startMovingRight(),
                onTapUp: (_) => game.stopMovingRight(),
                onTapCancel: () => game.stopMovingRight(),
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.cyan.withOpacity(0.3),
                        Colors.blue.withOpacity(0.2),
                        Colors.transparent,
                      ],
                    ),
                    border: Border.all(
                      color: Colors.cyan.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.arrow_circle_right_sharp,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ),

            // Pause button (only during gameplay)
            Positioned(
              top: 120,
              right: 20,
              child: GestureDetector(
                onTap: () => game.pauseGame(),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.orange.withOpacity(0.3),
                        Colors.red.withOpacity(0.2),
                        Colors.transparent,
                      ],
                    ),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  child: const Icon(Icons.pause, color: Colors.white, size: 24),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
