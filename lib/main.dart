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
        // backgroundColor: Colors.white,
        body: Stack(
          children: [
            // Background
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFFFFFFF), // Pure white
                    Color(0xFFF5F5F5), // Very light gray
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
                'GameOverMenu': (context, _) => GameOverPopup(game: game),
              },
            ),

            // Left movement button
            Positioned(
              left: 20,
              bottom: 20,
              child: CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.15),
                radius: 32,
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_circle_left_sharp,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: () => game.movePlayerLeft(),
                ),
              ),
            ),

            // Right movement button
            Positioned(
              right: 20,
              bottom: 20,
              child: CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.15),
                radius: 32,
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_circle_right_sharp,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: () => game.movePlayerRight(),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
