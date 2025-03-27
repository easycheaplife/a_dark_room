import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ui/screens/game_screen.dart';
import 'models/game_state.dart';
import 'engine/dev_tools.dart'; // 导入开发者工具

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // 确保 Flutter 绑定初始化
  final prefs = await SharedPreferences.getInstance(); // 初始化 shared_preferences

  final gameState = GameState(); // 创建 GameState 实例

  // 尝试加载最后一个存档
  try {
    print('Checking for save game...');
    bool hasSave = await gameState.hasSaveGame();
    print('Has save game: $hasSave');

    if (hasSave) {
      print('Attempting to load game...');
      bool success = await gameState.loadGame();
      print('Load game success: $success');

      if (!success) {
        print('Failed to load game, starting new game');
      }
    } else {
      print('No save game found, starting new game');
    }
  } catch (e) {
    print('Error during save game loading: $e');
  }

  // 初始化开发者工具
  DevTools.init(gameState);

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
