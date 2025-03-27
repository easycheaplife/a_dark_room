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
  bool _outsideUnlocked = false;
  int _currentIndex = 0; // 改为可变

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
  void _updateLocation() {
    _outsideUnlocked = widget.gameState.outsideUnlocked;
    _currentIndex = widget.gameState.currentLocation == 'room' ? 0 : 1;
  }

  @override
  Widget build(BuildContext context) {
    // 根据当前位置显示不同的屏幕
    switch (widget.gameState.currentLocation) {
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

  // 构建底部导航栏
  Widget _buildNavigationBar() {
    return BottomNavigationBar(
      backgroundColor: Colors.black,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.grey,
      currentIndex: _currentIndex,
      onTap: (index) {
        setState(() {
          widget.gameState.currentLocation = index == 0 ? 'room' : 'outside';
          widget.gameState.notifyListeners();
        });
      },
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: '房间',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.forest),
          label: '外部',
        ),
      ],
    );
  }
}
