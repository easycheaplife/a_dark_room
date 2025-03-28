import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../models/game_state.dart';
import '../../models/path_system.dart';
import '../../config/game_settings.dart';
import 'outfit_screen.dart';

/// 路径屏幕 - 显示探索准备界面
class PathScreen extends StatefulWidget {
  final GameState gameState;

  const PathScreen({
    super.key,
    required this.gameState,
  });

  @override
  State<PathScreen> createState() => _PathScreenState();
}

class _PathScreenState extends State<PathScreen> {
  late PathSystem _pathSystem;
  Map<String, int> _outfit = {};
  Map<String, int> _resources = {};
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _initPathScreen();
  }

  void _initPathScreen() {
    try {
      _pathSystem = widget.gameState.pathSystem;
      _updateState();

      if (kDebugMode) {
        print('路径屏幕初始化成功');
        print('背包物品: $_outfit');
        print('可用资源: $_resources');
      }
    } catch (e) {
      if (kDebugMode) {
        print('路径屏幕初始化失败: $e');
      }
      _statusMessage = '初始化错误: $e';
    }
  }

  // 更新状态
  void _updateState() {
    setState(() {
      _outfit = Map<String, int>.from(_pathSystem.outfit);
      _resources = Map<String, int>.from(widget.gameState.resources);
      _statusMessage = '';
    });
  }

  // 显示提示消息
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 使用OutfitScreen作为内容
    return _statusMessage.isNotEmpty
        ? Scaffold(
            backgroundColor: Colors.brown.shade100,
            appBar: AppBar(
              title: Text(GameSettings.languageManager
                  .get('prepare_exploration', category: 'path')),
              backgroundColor: Colors.brown.shade800,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _statusMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      _initPathScreen();
                    },
                    child: Text(GameSettings.languageManager
                        .get('retry', category: 'path')),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      widget.gameState.currentLocation = 'room';
                      widget.gameState.notifyListeners();
                    },
                    child: Text(GameSettings.languageManager
                        .get('return_to_room', category: 'path')),
                  ),
                ],
              ),
            ),
          )
        : OutfitScreen(
            gameState: widget.gameState,
            pathSystem: _pathSystem,
            worldSystem: widget.gameState.worldSystem,
            onEmbark: _embarkToWorld,
          );
  }

  // 出发到世界
  void _embarkToWorld() {
    if (kDebugMode) {
      print('尝试出发到世界');
      print('背包内容: ${_pathSystem.outfit}');
      print('可以出发: ${_pathSystem.canEmbark()}');
    }

    if (!_pathSystem.canEmbark()) {
      _showMessage(
          GameSettings.languageManager.get('embark_error', category: 'path'));
      return;
    }

    try {
      // 调用GameState的embarkonPath，它会处理所有出发逻辑
      bool success = widget.gameState.embarkonPath();
      if (success) {
        _showMessage(GameSettings.languageManager
            .get('going_to_world', category: 'path'));
        if (kDebugMode) {
          print('出发成功，正在前往世界');
        }
      } else {
        _showMessage(GameSettings.languageManager
            .get('cannot_embark', category: 'path'));
        if (kDebugMode) {
          print('出发失败');
        }
      }
    } catch (e) {
      _showMessage(GameSettings.languageManager.get('error', category: 'path') +
          e.toString());
      if (kDebugMode) {
        print('出发到世界出错: $e');
      }
    }
  }
}
