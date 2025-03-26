import 'package:flutter/material.dart';
import '../../engine/game_engine.dart';
import 'room_screen.dart';

/// 游戏主屏幕，根据游戏状态显示不同的游戏区域
class GameScreen extends StatefulWidget {
  const GameScreen({Key? key}) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final GameEngine _engine = GameEngine();
  String _currentLocation = 'room';

  @override
  void initState() {
    super.initState();
    // 监听游戏状态变化
    _engine.stateChangeNotifier.addListener(_updateScreen);
    // 初始状态
    _updateLocation();
  }

  @override
  void dispose() {
    _engine.stateChangeNotifier.removeListener(_updateScreen);
    super.dispose();
  }

  // 更新屏幕
  void _updateScreen() {
    setState(() {
      _updateLocation();
    });
  }

  // 更新当前位置
  void _updateLocation() {
    if (_engine.gameState != null) {
      _currentLocation = _engine.gameState!.currentLocation;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _buildCurrentScreen(),
      ),
    );
  }

  // 根据当前位置构建相应的屏幕
  Widget _buildCurrentScreen() {
    switch (_currentLocation) {
      case 'room':
        return const RoomScreen();
      // 随着游戏开发，这里会添加更多的屏幕
      default:
        return const RoomScreen();
    }
  }
}
