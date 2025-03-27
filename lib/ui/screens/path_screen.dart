import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../models/game_state.dart';
import '../../models/path_system.dart';
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
  Map<String, int> _bagSpace = {};
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
      _bagSpace = {
        'free': _pathSystem.getFreeSpace(),
        'total': _pathSystem.getCapacity(),
      };
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
              title: const Text('探索准备'),
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
                    child: const Text('重试'),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      widget.gameState.currentLocation = 'room';
                      widget.gameState.notifyListeners();
                    },
                    child: const Text('返回房间'),
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
      _showMessage('无法出发: 需要至少携带一些熏肉');
      return;
    }

    try {
      // 调用GameState的embarkonPath，它会处理所有出发逻辑
      bool success = widget.gameState.embarkonPath();
      if (success) {
        _showMessage('正在前往世界...');
        if (kDebugMode) {
          print('出发成功，正在前往世界');
        }
      } else {
        _showMessage('无法出发，请检查背包');
        if (kDebugMode) {
          print('出发失败');
        }
      }
    } catch (e) {
      _showMessage('出错: $e');
      if (kDebugMode) {
        print('出发到世界出错: $e');
      }
    }
  }
}
