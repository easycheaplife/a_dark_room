import 'package:flutter/material.dart';
import 'room_screen.dart';
import 'outside_screen.dart';
import '../../models/game_state.dart';
import 'world_screen.dart';
import 'path_screen.dart';
import 'package:flutter/foundation.dart';

/// 游戏主屏幕，根据游戏状态显示不同的游戏区域
class GameScreen extends StatefulWidget {
  final GameState gameState; // 添加 gameState 属性

  const GameScreen({
    super.key,
    required this.gameState,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  @override
  void initState() {
    super.initState();
    // 监听游戏状态变化
    widget.gameState.addListener(_onGameStateChanged);
    // 初始状态
    _updateLocation();
  }

  @override
  void dispose() {
    widget.gameState.removeListener(_onGameStateChanged);
    super.dispose();
  }

  // 游戏状态变化响应
  void _onGameStateChanged() {
    setState(() {
      _updateLocation();
    });
  }

  // 更新当前位置
  void _updateLocation() {}

  @override
  Widget build(BuildContext context) {
    // 添加延迟/预加载处理以改善界面切换性能
    return FutureBuilder<Widget>(
      future: _getScreenForLocation(widget.gameState.currentLocation),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // 显示加载指示器作为中间状态
          return Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: CircularProgressIndicator(
                color: Colors.brown.shade800,
              ),
            ),
          );
        } else if (snapshot.hasError) {
          // 处理错误
          if (kDebugMode) {
            print('Error loading screen: ${snapshot.error}');
          }
          // 返回基本错误视图
          return Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: Text(
                'Error loading game view',
                style: TextStyle(color: Colors.white),
              ),
            ),
          );
        } else {
          // 返回已加载的界面
          return snapshot.data ?? const SizedBox();
        }
      },
    );
  }

  // 根据位置异步创建相应的屏幕
  Future<Widget> _getScreenForLocation(String location) async {
    // 使用微任务让UI线程有机会响应
    await Future.microtask(() => null);

    switch (location) {
      case 'room':
        return RoomScreen(gameState: widget.gameState);
      case 'outside':
        return OutsideScreen(gameState: widget.gameState);
      case 'path':
        if (kDebugMode) {
          print('切换到路径屏幕');
        }
        return PathScreen(gameState: widget.gameState);
      case 'world':
        if (kDebugMode) {
          print('切换到世界屏幕');
        }
        return WorldScreen(
          gameState: widget.gameState,
          pathSystem: widget.gameState.pathSystem,
          worldSystem: widget.gameState.worldSystem,
        );
      default:
        return RoomScreen(gameState: widget.gameState);
    }
  }
}
