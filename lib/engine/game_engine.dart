import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/game_state.dart';

/// 游戏引擎类 - 负责游戏的核心逻辑
class GameEngine {
  // 单例模式
  static final GameEngine _instance = GameEngine._internal();
  factory GameEngine() => _instance;
  GameEngine._internal();

  // 游戏状态
  GameState? _gameState;
  // 状态改变监听器
  final _stateChangeNotifier = ValueNotifier<bool>(false);
  // 游戏循环定时器
  Timer? _gameLoopTimer;
  // 游戏循环间隔（毫秒）
  static const int _gameLoopInterval = 1000;

  // 初始化游戏引擎
  static void init() {
    if (kDebugMode) {
      print('游戏引擎初始化中...');
    }
    // 获取实例并初始化游戏状态
    _instance._gameState = GameState();
    // 启动游戏循环
    _instance._startGameLoop();
    // 模拟加载完成
    if (kDebugMode) {
      print('游戏引擎初始化完成');
    }
  }

  // 启动游戏循环
  void _startGameLoop() {
    _gameLoopTimer?.cancel();
    _gameLoopTimer = Timer.periodic(
      const Duration(milliseconds: _gameLoopInterval),
      (timer) => _updateGameLoop(),
    );
  }

  // 游戏循环更新
  void _updateGameLoop() {
    if (_gameState != null) {
      // 更新村民工作
      _gameState!.updateVillagerWork();
      // 通知状态变化
      _notifyStateChange();
    }
  }

  // 获取游戏状态
  GameState? get gameState => _gameState;

  // 获取状态改变通知器
  ValueNotifier<bool> get stateChangeNotifier => _stateChangeNotifier;

  // 更新游戏状态
  void updateGameState(Function(GameState state) updater) {
    if (_gameState != null) {
      updater(_gameState!);
      _notifyStateChange();
    }
  }

  // 通知状态变化
  void _notifyStateChange() {
    _stateChangeNotifier.value = !_stateChangeNotifier.value;
  }

  // 保存游戏
  Future<bool> saveGame() async {
    // 实际实现中，这里会保存到本地存储
    if (kDebugMode) {
      print('游戏已保存');
    }
    return true;
  }

  // 加载游戏
  Future<bool> loadGame() async {
    // 实际实现中，这里会从本地存储加载
    if (kDebugMode) {
      print('游戏已加载');
    }
    return true;
  }

  // 重置游戏
  void resetGame() {
    _gameState = GameState();
    _notifyStateChange();
    if (kDebugMode) {
      print('游戏已重置');
    }
  }

  // 清理资源
  void dispose() {
    _gameLoopTimer?.cancel();
  }
}
