import 'package:flame_game/game_over.dart';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'shooter_game.dart';

void main() {
  final game = ShooterGame();
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Stack(
          children: [
            GameWidget(
              game: game,
              overlayBuilderMap: {
                'GameOverMenu': (context, _) => GameOverPopup(game: game),
              },
            ),

            // Left Arrow Button
            Positioned(
              left: 20,
              bottom: 20,
              child: ElevatedButton(
                onPressed: () => game.movePlayerLeft(),
                child: const Icon(Icons.arrow_left),
              ),
            ),

            // Right Arrow Button
            Positioned(
              right: 20,
              bottom: 20,
              child: ElevatedButton(
                onPressed: () => game.movePlayerRight(),
                child: const Icon(Icons.arrow_right),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
