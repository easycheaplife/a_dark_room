import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ui/screens/game_screen.dart';
import 'models/game_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // 确保 Flutter 绑定初始化
  await SharedPreferences.getInstance(); // 初始化 shared_preferences
  final gameState = GameState(); // 创建 GameState 实例
  runApp(MyApp(gameState: gameState));
}

class MyApp extends StatelessWidget {
  final GameState gameState;

  const MyApp({
    super.key,
    required this.gameState,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'A Dark Room',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: GameScreen(gameState: gameState),
    );
  }
}
