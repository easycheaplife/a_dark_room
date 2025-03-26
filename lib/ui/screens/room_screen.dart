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
  bool _showBuildingsMenu = false; // 控制建筑菜单的显示
  Map<String, int> _resources = {}; // 资源
  Map<String, int> _buildings = {}; // 已建造的建筑

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
        _resources = Map<String, int>.from(_engine.gameState!.resources);
        _buildings =
            Map<String, int>.from(_engine.gameState!.room['buildings'] ?? {});
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

  // 建造建筑
  void _buildStructure(String buildingId) {
    if (_engine.gameState != null) {
      bool success = _engine.gameState!.buildStructure(buildingId);
      if (success) {
        String notification = _engine.gameState!
            .availableBuildings[buildingId]!['notification'] as String;
        _addLog(notification);

        // 检查是否解锁了外部世界
        if (buildingId == 'trap' && !_engine.gameState!.outsideUnlocked) {
          _engine.updateGameState((state) {
            state.outsideUnlocked = true;
          });
          _addLog('可以探索外面的世界了。');
        }

        // 更新建筑和资源显示
        _updateState();
      } else {
        Map<String, dynamic> cost = _engine.gameState!
            .availableBuildings[buildingId]!['cost'] as Map<String, dynamic>;
        _addLog('资源不足。需要: ${_formatCost(cost)}');
      }
    }
  }

  // 格式化建筑成本
  String _formatCost(Map<String, dynamic> cost) {
    List<String> parts = [];
    cost.forEach((resource, amount) {
      parts.add('$resource: $amount');
    });
    return parts.join(', ');
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
      child: Column(
        children: [
          Row(
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
          const SizedBox(height: 8),
          _buildResourceBar(),
        ],
      ),
    );
  }

  // 构建资源条
  Widget _buildResourceBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        _buildResourceIndicator('木头', _resources['wood'] ?? 0),
        if (_resources['fur'] != null && _resources['fur']! > 0)
          _buildResourceIndicator('毛皮', _resources['fur'] ?? 0),
        if (_resources['meat'] != null && _resources['meat']! > 0)
          _buildResourceIndicator('肉', _resources['meat'] ?? 0),
      ],
    );
  }

  // 构建单个资源指示器
  Widget _buildResourceIndicator(String name, int value) {
    return Padding(
      padding: const EdgeInsets.only(right: 15),
      child: Text(
        '$name: $value',
        style: TextStyle(
          color: Colors.grey.shade300,
          fontSize: 14,
        ),
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
            const SizedBox(height: 30),
            _buildBuildingsGrid(),
          ],
        ),
      ),
    );
  }

  // 构建建筑网格
  Widget _buildBuildingsGrid() {
    if (_buildings.isEmpty) {
      return const SizedBox();
    }

    List<Widget> buildingIcons = [];

    _buildings.forEach((buildingId, count) {
      if (count > 0 &&
          _engine.gameState?.availableBuildings[buildingId] != null) {
        String name = _engine.gameState!.availableBuildings[buildingId]!['name']
            as String;
        buildingIcons.add(
          Tooltip(
            message: '$name: $count',
            child: Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey.shade600),
              ),
              child: Center(
                child: Text(
                  name.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        );
      }
    });

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: buildingIcons,
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
      child: _showBuildingsMenu
          ? _buildBuildingsMenu()
          : _buildMainActionButtons(),
    );
  }

  // 构建主要动作按钮
  Widget _buildMainActionButtons() {
    bool outsideUnlocked = _engine.gameState?.outsideUnlocked ?? false;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _buildActionButton('生火', _fireLevel == 0, _lightFire),
        _buildActionButton('添加木头', _fireLevel > 0, _addWood),
        _buildActionButton('收集木头', true, _gatherWood),
        _buildActionButton('建造', _fireLevel > 0, () {
          setState(() {
            _showBuildingsMenu = true;
          });
        }),
        if (outsideUnlocked)
          _buildActionButton('外出', true, () {
            _engine.updateGameState((state) {
              state.currentLocation = 'outside';
            });
          }),
      ],
    );
  }

  // 构建建筑菜单
  Widget _buildBuildingsMenu() {
    List<Widget> buildingButtons = [];

    if (_engine.gameState != null) {
      _engine.gameState!.availableBuildings.forEach((id, building) {
        // 显示可用的建筑选项
        String name = building['name'] as String;
        String description = building['description'] as String;
        Map<String, dynamic> cost = building['cost'] as Map<String, dynamic>;

        // 检查建筑是否可以建造
        bool canBuild = _engine.gameState!.canBuild(id);

        buildingButtons.add(
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              border: Border.all(
                  color:
                      canBuild ? Colors.grey.shade700 : Colors.grey.shade800),
              borderRadius: BorderRadius.circular(4),
            ),
            child: ListTile(
              title: Text(
                name,
                style: TextStyle(
                  color: canBuild ? Colors.white : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    description,
                    style: TextStyle(
                      color: canBuild
                          ? Colors.grey.shade300
                          : Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '需要: ${_formatCost(cost)}',
                    style: TextStyle(
                      color: canBuild
                          ? Colors.grey.shade400
                          : Colors.grey.shade700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              onTap: canBuild
                  ? () {
                      _buildStructure(id);
                    }
                  : null,
            ),
          ),
        );
      });
    }

    return Column(
      children: [
        ...buildingButtons,
        ElevatedButton(
          onPressed: () {
            setState(() {
              _showBuildingsMenu = false;
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey.shade800,
          ),
          child: const Text('返回'),
        ),
      ],
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
