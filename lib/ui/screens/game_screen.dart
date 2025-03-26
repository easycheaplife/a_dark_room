import 'package:flutter/material.dart';
import '../../engine/game_engine.dart';
import 'room_screen.dart';
import 'outside_screen.dart';
import '../../models/game_state.dart';

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
  final GameEngine _engine = GameEngine();
  bool _outsideUnlocked = false;
  int _currentIndex = 0; // 改为可变

  @override
  void initState() {
    super.initState();
    // 监听游戏状态变化
    widget.gameState.addListener(_updateScreen);
    // 初始状态
    _updateLocation();
  }

  @override
  void dispose() {
    widget.gameState.removeListener(_updateScreen);
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
    _outsideUnlocked = widget.gameState.outsideUnlocked;
    _currentIndex = widget.gameState.currentLocation == 'room' ? 0 : 1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: [
            RoomScreen(gameState: widget.gameState),
            OutsideScreen(gameState: widget.gameState),
          ],
        ),
      ),
      bottomNavigationBar: _outsideUnlocked ? _buildNavigationBar() : null,
    );
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
