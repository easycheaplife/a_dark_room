import 'package:flutter/material.dart';
import '../../models/game_state.dart';
import 'room_screen.dart';
import 'outside_screen.dart';
import 'path_screen.dart';
import 'world_screen.dart';
import 'package:flutter/foundation.dart';

/// 游戏主屏幕，根据状态显示不同的页面
class GameScreen extends StatefulWidget {
  final GameState gameState;

  const GameScreen({super.key, required this.gameState});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  // 上一次显示的位置
  String? _lastLocation;

  // 页面控制器
  final PageController _pageController = PageController();

  // 使用IndexedStack来保持所有页面状态
  late List<Widget> _screens;

  // 页面索引映射
  final Map<String, int> _pageIndexes = {
    'room': 0,
    'outside': 1,
    'path': 2,
    'world': 3,
  };

  // 当前页面索引
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();

    // 添加应用生命周期观察者
    WidgetsBinding.instance.addObserver(this);

    // 初始化屏幕列表
    _initScreens();

    // 低频率监听位置变化
    widget.gameState.addListener(_onLocationChanged);

    // 初始化当前位置
    _lastLocation = widget.gameState.currentLocation;
    _updateCurrentIndex();
  }

  void _initScreens() {
    // 初始化所有页面，使用IndexedStack保持状态
    _screens = [
      RoomScreen(gameState: widget.gameState),
      OutsideScreen(gameState: widget.gameState),
      PathScreen(gameState: widget.gameState),
      WorldScreen(
        gameState: widget.gameState,
        pathSystem: widget.gameState.pathSystem,
        worldSystem: widget.gameState.worldSystem,
      ),
    ];
  }

  // 只处理位置变化，避免其他状态引起不必要的刷新
  void _onLocationChanged() {
    final newLocation = widget.gameState.currentLocation;
    if (_lastLocation != newLocation) {
      _lastLocation = newLocation;
      _updateCurrentIndex();
    }
  }

  // 更新当前页面索引
  void _updateCurrentIndex() {
    final location = widget.gameState.currentLocation;
    if (_pageIndexes.containsKey(location)) {
      setState(() {
        _currentIndex = _pageIndexes[location]!;
      });
    }
  }

  @override
  void dispose() {
    // 移除观察者
    WidgetsBinding.instance.removeObserver(this);

    // 取消监听
    widget.gameState.removeListener(_onLocationChanged);

    // 释放控制器
    _pageController.dispose();

    super.dispose();
  }

  // 应用生命周期变化回调
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // 应用进入后台时保存游戏状态
      widget.gameState.saveGameState();
    } else if (state == AppLifecycleState.resumed) {
      // 应用回到前台，检查是否需要更新
      _updateCurrentIndex();
    }
  }

  @override
  Widget build(BuildContext context) {
    // 使用IndexedStack保持页面状态，避免重建
    return IndexedStack(
      index: _currentIndex,
      children: _screens,
    );
  }
}
