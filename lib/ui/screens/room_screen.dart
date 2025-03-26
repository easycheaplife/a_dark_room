import 'package:flutter/material.dart';
import '../../engine/game_engine.dart';

/// 房间屏幕 - 游戏的起始区域
class RoomScreen extends StatefulWidget {
  const RoomScreen({Key? key}) : super(key: key);

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  final GameEngine _engine = GameEngine();
  int _fireLevel = 0; // 火堆等级
  String _temperature = 'cold'; // 温度
  List<String> _logs = ['一个黑暗的房间。']; // 游戏日志

  @override
  void initState() {
    super.initState();
    _engine.stateChangeNotifier.addListener(_updateState);
    _updateState();
  }

  @override
  void dispose() {
    _engine.stateChangeNotifier.removeListener(_updateState);
    super.dispose();
  }

  // 更新状态
  void _updateState() {
    if (_engine.gameState != null) {
      setState(() {
        _fireLevel = _engine.gameState!.room['fire'] as int;
        _temperature = _engine.gameState!.room['temperature'] as String;
      });
    }
  }

  // 添加日志
  void _addLog(String message) {
    setState(() {
      _logs.add(message);
      // 保持日志不超过10条
      if (_logs.length > 10) {
        _logs.removeAt(0);
      }
    });
  }

  // 生火
  void _lightFire() {
    if (_engine.gameState != null) {
      bool hasWood = _engine.gameState!.useResource('wood', 5);
      if (hasWood) {
        _engine.updateGameState((state) {
          state.room['fire'] = 1;
          state.room['temperature'] = 'warm';
        });
        _addLog('火堆点燃了。房间变暖了。');
      } else {
        _addLog('没有足够的木头。');
      }
    }
  }

  // 添加木头
  void _addWood() {
    if (_engine.gameState != null) {
      if (_fireLevel == 0) {
        _addLog('没有火堆。');
        return;
      }

      bool hasWood = _engine.gameState!.useResource('wood', 1);
      if (hasWood) {
        _engine.updateGameState((state) {
          int currentFire = state.room['fire'] as int;
          if (currentFire < 3) {
            state.room['fire'] = currentFire + 1;
          }

          if (currentFire == 1) {
            _addLog('火堆燃烧更旺了。');
          } else if (currentFire == 2) {
            _addLog('火堆熊熊燃烧。');
            state.room['temperature'] = 'hot';
          }
        });
      } else {
        _addLog('没有木头。');
      }
    }
  }

  // 收集木头
  void _gatherWood() {
    _engine.updateGameState((state) {
      state.addResource('wood', 1);
    });
    _addLog('收集了一些木头。');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        _buildRoomView(),
        _buildLogView(),
        _buildActionButtons(),
      ],
    );
  }

  // 构建头部信息
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(10),
      color: Colors.black,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'A Dark Room',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '温度: $_temperature',
            style: TextStyle(
              color: _getTemperatureColor(),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // 获取温度颜色
  Color _getTemperatureColor() {
    switch (_temperature) {
      case 'cold':
        return Colors.lightBlue;
      case 'warm':
        return Colors.orange;
      case 'hot':
        return Colors.red;
      default:
        return Colors.white;
    }
  }

  // 构建房间视图
  Widget _buildRoomView() {
    return Expanded(
      flex: 2,
      child: Container(
        width: double.infinity,
        color: Colors.black,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_fire_department,
              color: _getFireColor(),
              size: 80,
            ),
            const SizedBox(height: 20),
            Text(
              _getFireDescription(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // 获取火堆颜色
  Color _getFireColor() {
    switch (_fireLevel) {
      case 0:
        return Colors.grey.shade700;
      case 1:
        return Colors.orange.shade300;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.deepOrange;
      default:
        return Colors.grey;
    }
  }

  // 获取火堆描述
  String _getFireDescription() {
    switch (_fireLevel) {
      case 0:
        return '这里很黑，很冷。\n需要生火。';
      case 1:
        return '火堆噼啪作响。';
      case 2:
        return '火堆燃烧得很好。';
      case 3:
        return '火堆熊熊燃烧。';
      default:
        return '';
    }
  }

  // 构建日志视图
  Widget _buildLogView() {
    return Container(
      height: 150,
      width: double.infinity,
      color: Colors.black,
      padding: const EdgeInsets.all(10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade800),
          color: Colors.black,
        ),
        child: ListView.builder(
          itemCount: _logs.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Text(
                _logs[index],
                style: TextStyle(
                  color: index == _logs.length - 1 ? Colors.white : Colors.grey,
                  fontSize: 14,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // 构建动作按钮
  Widget _buildActionButtons() {
    return Container(
      width: double.infinity,
      color: Colors.black,
      padding: const EdgeInsets.all(10),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _buildActionButton('生火', _fireLevel == 0, _lightFire),
          _buildActionButton('添加木头', _fireLevel > 0, _addWood),
          _buildActionButton('收集木头', true, _gatherWood),
        ],
      ),
    );
  }

  // 构建单个动作按钮
  Widget _buildActionButton(String text, bool enabled, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: enabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey.shade800,
        disabledBackgroundColor: Colors.grey.shade900,
        foregroundColor: Colors.white,
        disabledForegroundColor: Colors.grey,
      ),
      child: Text(text),
    );
  }
}
