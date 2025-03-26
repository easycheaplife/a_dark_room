import 'package:flutter/material.dart';
import 'ui/screens/game_screen.dart';
import 'engine/game_engine.dart';

void main() {
  // 确保GameEngine在应用启动时初始化
  GameEngine.init();
  runApp(const ADarkRoomApp());
}

class ADarkRoomApp extends StatelessWidget {
  const ADarkRoomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'A Dark Room',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.grey,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Courier New',
      ),
      home: const GameScreen(),
    );
  }
}
