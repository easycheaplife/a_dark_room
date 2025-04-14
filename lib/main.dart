import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'ui/screens/game_screen.dart';
import 'models/game_state.dart';
import 'engine/dev_tools.dart'; // 导入开发者工具
import 'config/game_settings.dart'; // 导入游戏设置

// 始终打印日志，即使在release模式下
void releaseLog(String message) {
  // 这个方法会在release模式下也打印日志
  print("RELEASE_LOG: $message");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // 确保 Flutter 绑定初始化

  // 日志记录
  releaseLog("应用启动");

  // 初始化游戏设置和语言
  await GameSettings.init();
  releaseLog("游戏设置初始化完成");

  // 创建 GameState 实例
  final gameState = GameState();
  releaseLog("GameState实例创建");

  // 尝试加载最后一个存档
  try {
    _log('Checking for save game...');
    releaseLog("检查是否有存档");
    bool hasSave = await gameState.hasSaveGame();
    _log('Has save game: $hasSave');
    releaseLog("存在存档: $hasSave");

    if (hasSave) {
      _log('Attempting to load game...');
      releaseLog("尝试加载存档");
      bool success = await gameState.loadGame();
      _log('Load game success: $success');
      releaseLog("加载存档结果: $success");

      if (!success) {
        _log('Failed to load game, starting new game');
        releaseLog("加载失败，开始新游戏");
      }
    } else {
      _log('No save game found, starting new game');
      releaseLog("未找到存档，开始新游戏");
    }
  } catch (e) {
    _log('Error during save game loading: $e');
    releaseLog("加载存档出错: $e");
  }

  // 初始化开发者工具
  DevTools.init(gameState);
  releaseLog("开发者工具初始化完成");

  // 检查villagerTypes数据
  releaseLog("villagerTypes数量: ${gameState.villagerTypes.length}");

  runApp(MyApp(gameState: gameState));
}

// Helper method to log messages only in debug mode
void _log(String message) {
  if (kDebugMode) {
    print(message);
  }
}

class MyApp extends StatelessWidget {
  final GameState gameState;

  const MyApp({
    super.key,
    required this.gameState,
  });

  @override
  Widget build(BuildContext context) {
    releaseLog("构建MyApp");
    return MaterialApp(
      title: 'A Dark Room',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
      ),
      home: GameScreen(gameState: gameState),
    );
  }
}
