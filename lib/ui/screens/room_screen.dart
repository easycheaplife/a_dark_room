import 'package:flutter/material.dart';
import '../../models/game_state.dart';
import '../../models/event_system.dart';

/// 房间屏幕 - 游戏的起始区域
class RoomScreen extends StatefulWidget {
  final GameState gameState;

  const RoomScreen({
    super.key,
    required this.gameState,
  });

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  int _fireLevel = 0; // 火堆等级
  String _temperature = 'cold'; // 温度
  final List<String> _logs = ['一个黑暗的房间。']; // 游戏日志
  bool _showBuildingsMenu = false; // 控制建筑菜单的显示
  bool _showVillagersMenu = false; // 控制村民菜单的显示
  bool _showTradeMenu = false;
  Map<String, int> _resources = {}; // 资源
  Map<String, int> _buildings = {}; // 已建造的建筑
  Map<String, dynamic> _population = {}; // 村民状态

  @override
  void initState() {
    super.initState();
    // 添加初始金钱
    if (!widget.gameState.resources.containsKey('money')) {
      widget.gameState.resources['money'] = 100; // 给玩家一些初始金钱
    }

    // 添加事件检查
    widget.gameState.initEventSystem();
    _updateState();
  }

  // 更新状态
  void _updateState() {
    setState(() {
      _fireLevel = widget.gameState.room['fire'] as int;
      _temperature = widget.gameState.room['temperature'] as String;
      _resources = Map<String, int>.from(widget.gameState.resources);
      _buildings =
          Map<String, int>.from(widget.gameState.room['buildings'] ?? {});
      _population = Map<String, dynamic>.from(widget.gameState.population);

      // 检查是否有新事件
      if (widget.gameState.currentEvent != null) {
        _showEventDialog();
      }
    });
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
    bool hasWood = widget.gameState.useResource('wood', 5);
    if (hasWood) {
      widget.gameState.room['fire'] = 1;
      widget.gameState.room['temperature'] = 'warm';
      widget.gameState.notifyListeners();
      _addLog('火堆点燃了。房间变暖了。');
    } else {
      _addLog('没有足够的木头。');
    }
  }

  // 添加木头
  void _addWood() {
    if (_fireLevel == 0) {
      _addLog('没有火堆。');
      return;
    }

    bool hasWood = widget.gameState.useResource('wood', 1);
    if (hasWood) {
      int currentFire = widget.gameState.room['fire'] as int;
      if (currentFire < 3) {
        widget.gameState.room['fire'] = currentFire + 1;
      }

      if (currentFire == 1) {
        _addLog('火堆燃烧更旺了。');
      } else if (currentFire == 2) {
        _addLog('火堆熊熊燃烧。');
        widget.gameState.room['temperature'] = 'hot';
      }
      widget.gameState.notifyListeners();
    } else {
      _addLog('没有木头。');
    }
  }

  // 收集木头
  void _gatherWood() {
    widget.gameState.addResource('wood', 100);
    widget.gameState.notifyListeners();
    _addLog('收集了一些木头。');
  }

  // 建造建筑
  void _buildStructure(String buildingId) {
    bool success = widget.gameState.buildStructure(buildingId);
    if (success) {
      String notification = widget
          .gameState.availableBuildings[buildingId]!['notification'] as String;
      _addLog(notification);

      // 检查是否解锁了外部世界
      if (buildingId == 'trap' && !widget.gameState.outsideUnlocked) {
        widget.gameState.outsideUnlocked = true;
        widget.gameState.notifyListeners();
        _addLog('可以探索外面的世界了。');
      }

      // 更新建筑和资源显示
      _updateState();
    } else {
      Map<String, dynamic> cost = widget.gameState
          .availableBuildings[buildingId]!['cost'] as Map<String, dynamic>;
      _addLog('资源不足。需要: ${_formatCost(cost)}');
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

  // 修改资源显示方法
  Widget _buildResourceDisplay() {
    final Map<String, List<String>> resourceGroups = {
      '基础资源': ['wood', 'meat', 'water'],
      '狩猎资源': ['fur', 'scales', 'teeth', 'leather'],
      '制作材料': ['cloth', 'herbs', 'coal', 'iron', 'steel', 'sulphur'],
      '食物': ['cured meat'],
    };

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        border: Border.all(color: Colors.grey.shade800),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: resourceGroups.entries.map((group) {
          final resources = group.value
              .where((resource) => (_resources[resource] ?? 0) > 0)
              .toList();

          if (resources.isEmpty) return const SizedBox.shrink();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                group.key,
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Wrap(
                spacing: 10,
                children: resources.map((resource) {
                  final storage =
                      widget.gameState.getResourceStorage()[resource]!;
                  final amount = storage['amount']!;
                  final limit = storage['limit']!;
                  final percentage = (amount / limit * 100).round();

                  return Tooltip(
                    message: '$resource: $amount/$limit',
                    child: Text(
                      '$resource: $amount',
                      style: TextStyle(
                        color: percentage >= 90 ? Colors.orange : Colors.white,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
            ],
          );
        }).toList(),
      ),
    );
  }

  // 构建村民工作状态显示
  Widget _buildWorkerStatus() {
    if (_population['workers'] == null ||
        (_population['workers'] as Map).isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        border: Border.all(color: Colors.grey.shade800),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '工作状态',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          ...widget.gameState.villagerTypes.entries.map((entry) {
            final type = entry.key;
            final info = entry.value;
            final count = _population['workers']?[type] ?? 0;
            if (count == 0) return const SizedBox.shrink();

            final efficiency =
                widget.gameState.calculateVillagerEfficiency(type);
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${info['name']}: $count',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  Text(
                    '效率: ${(efficiency * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: Colors.grey.shade300,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _showBuildingsMenu
                    ? _buildBuildingsMenu()
                    : _showVillagersMenu
                        ? _buildVillagersMenu()
                        : _showTradeMenu
                            ? _buildTradeMenu()
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildFireStatus(),
                                  const SizedBox(height: 16),
                                  _buildResourceDisplay(),
                                  const SizedBox(height: 16),
                                  _buildWorkerStatus(),
                                  const SizedBox(height: 16),
                                  _buildBuildingsGrid(),
                                  const SizedBox(height: 16),
                                  _buildGameLog(),
                                ],
                              ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border(
                  top: BorderSide(
                    color: Colors.grey.shade900,
                    width: 1,
                  ),
                ),
              ),
              child: _buildActionButtons(),
            ),
          ],
        ),
      ),
    );
  }

  // 构建火堆状态
  Widget _buildFireStatus() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        border: Border.all(color: Colors.grey.shade800),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '火堆状态',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '温度: $_temperature',
                style: TextStyle(
                  color: _getTemperatureColor(),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: Icon(
              Icons.local_fire_department,
              color: _getFireColor(),
              size: 40,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              _getFireDescription(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
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
          widget.gameState.availableBuildings[buildingId] != null) {
        String name =
            widget.gameState.availableBuildings[buildingId]!['name'] as String;
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
  Widget _buildGameLog() {
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
      padding: const EdgeInsets.only(
        left: 10,
        right: 10,
        top: 8,
        bottom: 0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_showBuildingsMenu && !_showVillagersMenu && !_showTradeMenu)
            _buildMainActionButtons(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // 构建主要动作按钮
  Widget _buildMainActionButtons() {
    bool outsideUnlocked = widget.gameState.outsideUnlocked;
    bool storeOpened = widget.gameState.storeOpened;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _buildActionButton('生火', _fireLevel == 0, () {
          _lightFire();
          _updateState();
        }),
        _buildActionButton('添加木头', _fireLevel > 0, () {
          _addWood();
          _updateState();
        }),
        _buildActionButton('收集木头', true, () {
          _gatherWood();
          _updateState();
        }),
        _buildActionButton('建造', _fireLevel > 0, () {
          setState(() {
            _showBuildingsMenu = true;
            _showVillagersMenu = false;
            _showTradeMenu = false;
          });
        }),
        _buildActionButton('村民', _fireLevel > 0, () {
          setState(() {
            _showVillagersMenu = true;
            _showBuildingsMenu = false;
            _showTradeMenu = false;
          });
        }),
        if (storeOpened)
          _buildActionButton('交易', true, () {
            setState(() {
              _showTradeMenu = true;
              _showBuildingsMenu = false;
              _showVillagersMenu = false;
            });
          }),
        if (outsideUnlocked)
          _buildActionButton('外出', true, () {
            setState(() {
              widget.gameState.currentLocation = 'outside';
              widget.gameState.notifyListeners();
            });
          }),
        _buildActionButton('保存', true, () async {
          try {
            await widget.gameState.saveGame();
            _addLog('游戏已保存。');
          } catch (e) {
            _addLog('保存失败：$e');
          }
        }),
        _buildActionButton('读取', true, () async {
          try {
            bool success = await widget.gameState.loadGame();
            if (success) {
              _addLog('游戏已读取。');
              _updateState();
            } else {
              _addLog('没有找到存档。');
            }
          } catch (e) {
            _addLog('读取失败：$e');
          }
        }),
      ],
    );
  }

  // 修改建筑菜单项显示
  Widget _buildBuildingMenuItem(
      String id, Map<String, dynamic> building, bool canBuild) {
    String name = building['name'] as String;
    String description = building['description'] as String;
    Map<String, dynamic> cost = building['cost'] as Map<String, dynamic>;
    int currentLevel = widget.gameState.buildingLevels[id] ?? 1;
    bool canUpgrade = widget.gameState.canUpgradeBuilding(id);
    int count = _buildings[id] ?? 0;

    // 获取维护成本
    String maintenanceText = '';
    if (widget.gameState.buildingMaintenance.containsKey(id)) {
      Map<String, dynamic> maintenance =
          widget.gameState.buildingMaintenance[id]!;
      List<String> maintenanceCosts = [];
      maintenance.forEach((resource, amount) {
        if (resource != 'interval') {
          maintenanceCosts.add('$resource: $amount');
        }
      });
      maintenanceText = '维护: ${maintenanceCosts.join(', ')}';
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        border: Border.all(
          color: canBuild ? Colors.grey.shade700 : Colors.grey.shade800,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          ListTile(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$name ($count)',
                  style: TextStyle(
                    color: canBuild ? Colors.white : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (count > 0)
                  Text(
                    'Lv.$currentLevel',
                    style: TextStyle(
                      color: Colors.amber,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: TextStyle(
                    color:
                        canBuild ? Colors.grey.shade300 : Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                Text(
                  '需要: ${_formatCost(cost)}',
                  style: TextStyle(
                    color:
                        canBuild ? Colors.grey.shade400 : Colors.grey.shade700,
                    fontSize: 12,
                  ),
                ),
                if (maintenanceText.isNotEmpty)
                  Text(
                    maintenanceText,
                    style: TextStyle(
                      color: Colors.orange.shade300,
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
          if (count > 0 && currentLevel < 3)
            Padding(
              padding: const EdgeInsets.only(bottom: 8, left: 16, right: 16),
              child: ElevatedButton(
                onPressed: canUpgrade
                    ? () {
                        if (widget.gameState.upgradeBuilding(id)) {
                          _addLog('升级了$name到${currentLevel + 1}级。');
                          _updateState();
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade900,
                  minimumSize: const Size(double.infinity, 30),
                ),
                child: Text(
                  '升级到 ${currentLevel + 1} 级',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 更新建筑菜单
  Widget _buildBuildingsMenu() {
    List<Widget> buildingButtons = [];

    if (widget.gameState != null) {
      widget.gameState.availableBuildings.forEach((id, building) {
        bool canBuild = widget.gameState.canBuild(id);
        buildingButtons.add(_buildBuildingMenuItem(id, building, canBuild));
      });
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...buildingButtons,
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _showBuildingsMenu = false;
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey.shade800,
            minimumSize: const Size(double.infinity, 40),
          ),
          child: const Text('返回'),
        ),
      ],
    );
  }

  // 构建村民菜单
  Widget _buildVillagersMenu() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 显示村民状态
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            border: Border.all(color: Colors.grey.shade800),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '总人口: ${_population['total'] ?? 0}/${_population['max'] ?? 0}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  Text(
                    '幸福度: ${_population['happiness']?.toStringAsFixed(0) ?? 100}%',
                    style: TextStyle(
                      color:
                          _getHappinessColor(_population['happiness'] ?? 100),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // 显示可招募的村民
        ...widget.gameState.villagerTypes.entries.map((entry) {
          final type = entry.key;
          final info = entry.value;
          final count = _population['workers']?[type] ?? 0;

          // 检查是否可以招募
          bool canRecruit = widget.gameState.canRecruitVillager(type);

          return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              border: Border.all(
                color: canRecruit ? Colors.grey.shade700 : Colors.grey.shade800,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: ListTile(
              title: Text(
                '$type ($count)',
                style: TextStyle(
                  color: canRecruit ? Colors.white : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    info['description'],
                    style: TextStyle(
                      color: canRecruit
                          ? Colors.grey.shade300
                          : Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '需要: ${_formatCost(info['cost'] as Map<String, dynamic>)}',
                    style: TextStyle(
                      color: canRecruit
                          ? Colors.grey.shade400
                          : Colors.grey.shade700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              onTap: canRecruit
                  ? () {
                      if (widget.gameState.recruitVillager(type)) {
                        _addLog('招募了一个$type。');
                      }
                    }
                  : null,
            ),
          );
        }),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _showVillagersMenu = false;
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey.shade800,
            minimumSize: const Size(double.infinity, 40),
          ),
          child: const Text('返回'),
        ),
      ],
    );
  }

  // 获取幸福度颜色
  Color _getHappinessColor(double happiness) {
    if (happiness >= 80) return Colors.green;
    if (happiness >= 60) return Colors.yellow;
    return Colors.red;
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

  // 添加事件对话框显示
  void _showEventDialog() {
    if (widget.gameState?.currentEvent == null) return;

    GameEvent event = widget.gameState.currentEvent!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: Text(
          event.title,
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              event.description,
              style: TextStyle(color: Colors.grey.shade300),
            ),
            if (event.choices != null) ...[
              const SizedBox(height: 16),
              ...event.choices!.map((choice) {
                bool canChoose = widget.gameState.eventSystem
                    .canChoose(choice, widget.gameState!);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ElevatedButton(
                    onPressed: canChoose
                        ? () {
                            widget.gameState.makeEventChoice(choice);
                            Navigator.of(context).pop();
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade800,
                      minimumSize: const Size(double.infinity, 40),
                    ),
                    child: Text(choice.text),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  // 添加交易菜单
  Widget _buildTradeMenu() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 400),
      child: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                border: Border.all(color: Colors.grey.shade800),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '金钱: ${_resources['money'] ?? 0}',
                    style: const TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '价格每5分钟更新一次',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            ...widget.gameState.tradeSystem.tradeItems.entries.map((entry) {
              final itemId = entry.key;
              final item = entry.value;
              final currentAmount = _resources[itemId] ?? 0;
              final buyPrice =
                  widget.gameState.tradeSystem.calculateBuyPrice(itemId, 1);
              final sellPrice =
                  widget.gameState.tradeSystem.calculateSellPrice(itemId, 1);

              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  border: Border.all(color: Colors.grey.shade700),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: ListTile(
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '持有: $currentAmount',
                        style: TextStyle(
                          color: Colors.grey.shade300,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '买入: $buyPrice',
                        style: TextStyle(
                          color: Colors.green.shade300,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '卖出: $sellPrice',
                        style: TextStyle(
                          color: Colors.red.shade300,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        color: Colors.red.shade300,
                        onPressed: widget.gameState.canSell(itemId, 1)
                            ? () {
                                if (widget.gameState.sellItem(itemId, 1)) {
                                  _addLog('卖出了1个${item.name}');
                                  _updateState();
                                }
                              }
                            : null,
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        color: Colors.green.shade300,
                        onPressed: widget.gameState.canBuy(itemId, 1)
                            ? () {
                                if (widget.gameState.buyItem(itemId, 1)) {
                                  _addLog('购买了1个${item.name}');
                                  _updateState();
                                }
                              }
                            : null,
                      ),
                    ],
                  ),
                ),
              );
            }),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _showTradeMenu = false;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade800,
                minimumSize: const Size(double.infinity, 40),
              ),
              child: const Text('返回'),
            ),
          ],
        ),
      ),
    );
  }
}
