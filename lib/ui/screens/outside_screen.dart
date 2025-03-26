import 'package:flutter/material.dart';
import '../../engine/game_engine.dart';
import '../../models/game_state.dart';
import 'dart:math';

/// 户外屏幕 - 村庄和探索
class OutsideScreen extends StatefulWidget {
  final GameState gameState;

  const OutsideScreen({
    super.key,
    required this.gameState,
  });

  @override
  State<OutsideScreen> createState() => _OutsideScreenState();
}

class _OutsideScreenState extends State<OutsideScreen> {
  final List<String> _logs = []; // 游戏日志
  Map<String, int> _resources = {}; // 资源
  bool _isExploring = false;
  bool _isScavenging = false;
  bool _isHunting = false;
  int _explorationTimeLeft = 0;
  int _scavengingTimeLeft = 0;
  int _huntingTimeLeft = 0;
  String _currentLocation = 'forest';
  List<String> _discoveredLocations = [];
  Map<String, dynamic> _locationInfo = {};

  @override
  void initState() {
    super.initState();
    widget.gameState.addListener(_updateState);
    _updateState();
    _loadLocationData();
  }

  @override
  void dispose() {
    widget.gameState.removeListener(_updateState);
    super.dispose();
  }

  // 更新状态
  void _updateState() {
    setState(() {
      _resources = Map<String, int>.from(widget.gameState.resources);
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

  void _loadLocationData() {
    // 加载已发现的位置
    _discoveredLocations =
        List<String>.from(widget.gameState.world['discovered_locations'] ?? []);
    _locationInfo = Map<String, dynamic>.from(
        widget.gameState.world['location_info'] ?? {});

    // 如果没有发现任何位置，添加默认的森林
    if (_discoveredLocations.isEmpty) {
      _discoveredLocations.add('forest');
      _locationInfo['forest'] = {
        'name': '森林',
        'description': '一片茂密的森林，有丰富的资源。',
        'resources': ['wood', 'meat', 'fur'],
        'dangers': ['wolf'],
        'exploration_time': 30,
        'scavenging_time': 20,
        'hunting_time': 15,
      };
      _updateWorldState();
    }
  }

  void _updateWorldState() {
    widget.gameState.world['discovered_locations'] = _discoveredLocations;
    widget.gameState.world['location_info'] = _locationInfo;
    widget.gameState.notifyListeners();
  }

  void _startExploring() {
    if (_isExploring) return;

    setState(() {
      _isExploring = true;
      _explorationTimeLeft =
          _locationInfo[_currentLocation]?['exploration_time'] ?? 30;
    });

    _explorationTimer();
  }

  void _startScavenging() {
    if (_isScavenging) return;

    setState(() {
      _isScavenging = true;
      _scavengingTimeLeft =
          _locationInfo[_currentLocation]?['scavenging_time'] ?? 20;
    });

    _scavengingTimer();
  }

  void _startHunting() {
    if (_isHunting) return;

    setState(() {
      _isHunting = true;
      _huntingTimeLeft = _locationInfo[_currentLocation]?['hunting_time'] ?? 15;
    });

    _huntingTimer();
  }

  void _explorationTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;

      setState(() {
        _explorationTimeLeft--;
      });

      if (_explorationTimeLeft > 0) {
        _explorationTimer();
      } else {
        _completeExploration();
      }
    });
  }

  void _scavengingTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;

      setState(() {
        _scavengingTimeLeft--;
      });

      if (_scavengingTimeLeft > 0) {
        _scavengingTimer();
      } else {
        _completeScavenging();
      }
    });
  }

  void _huntingTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;

      setState(() {
        _huntingTimeLeft--;
      });

      if (_huntingTimeLeft > 0) {
        _huntingTimer();
      } else {
        _completeHunting();
      }
    });
  }

  void _completeExploration() {
    setState(() {
      _isExploring = false;
    });

    // 随机发现新位置
    if (Random().nextDouble() < 0.3) {
      // 30%的概率发现新位置
      String newLocation = _generateNewLocation();
      if (newLocation.isNotEmpty) {
        _discoveredLocations.add(newLocation);
        _locationInfo[newLocation] = _generateLocationInfo(newLocation);
        _updateWorldState();
        _showNewLocationDialog(newLocation);
      }
    }
  }

  void _completeScavenging() {
    setState(() {
      _isScavenging = false;
    });

    // 获取当前位置可获得的资源
    List<String> availableResources =
        _locationInfo[_currentLocation]?['resources'] ?? [];
    if (availableResources.isNotEmpty) {
      String resource =
          availableResources[Random().nextInt(availableResources.length)];
      int amount = Random().nextInt(3) + 1;
      widget.gameState.addResource(resource, amount);
      widget.gameState.addLog(
          '在${_locationInfo[_currentLocation]['name']}中找到了 $amount 个 $resource');
    }
  }

  void _completeHunting() {
    setState(() {
      _isHunting = false;
    });

    // 检查是否有危险生物
    List<String> dangers = _locationInfo[_currentLocation]?['dangers'] ?? [];
    if (dangers.isNotEmpty && Random().nextDouble() < 0.4) {
      // 40%的概率遇到危险
      String danger = dangers[Random().nextInt(dangers.length)];
      _handleDanger(danger);
    } else {
      // 正常狩猎结果
      widget.gameState.startHunting(_currentLocation);
    }
  }

  String _generateNewLocation() {
    List<String> possibleLocations = [
      'cave',
      'river',
      'mountain',
      'desert',
      'swamp',
      'ruins',
    ];

    // 过滤掉已发现的位置
    possibleLocations.removeWhere((loc) => _discoveredLocations.contains(loc));
    if (possibleLocations.isEmpty) return '';

    return possibleLocations[Random().nextInt(possibleLocations.length)];
  }

  Map<String, dynamic> _generateLocationInfo(String location) {
    Map<String, dynamic> info = {
      'name': '',
      'description': '',
      'resources': [],
      'dangers': [],
      'exploration_time': 30,
      'scavenging_time': 20,
      'hunting_time': 15,
    };

    switch (location) {
      case 'cave':
        info['name'] = '洞穴';
        info['description'] = '一个黑暗的洞穴，可能藏有宝藏。';
        info['resources'] = ['coal', 'iron', 'sulphur'];
        info['dangers'] = ['bat', 'spider'];
        break;
      case 'river':
        info['name'] = '河流';
        info['description'] = '一条清澈的河流，有丰富的鱼类资源。';
        info['resources'] = ['water', 'fish'];
        info['dangers'] = ['crocodile'];
        break;
      case 'mountain':
        info['name'] = '山脉';
        info['description'] = '陡峭的山脉，富含矿物。';
        info['resources'] = ['iron', 'coal', 'stone'];
        info['dangers'] = ['bear'];
        break;
      case 'desert':
        info['name'] = '沙漠';
        info['description'] = '一片荒芜的沙漠，有稀有的资源。';
        info['resources'] = ['sand', 'cactus'];
        info['dangers'] = ['scorpion'];
        break;
      case 'swamp':
        info['name'] = '沼泽';
        info['description'] = '潮湿的沼泽地，有独特的资源。';
        info['resources'] = ['herbs', 'mushroom'];
        info['dangers'] = ['snake'];
        break;
      case 'ruins':
        info['name'] = '废墟';
        info['description'] = '古老的废墟，可能藏有珍贵的物品。';
        info['resources'] = ['scrap', 'artifact'];
        info['dangers'] = ['ghost'];
        break;
    }

    return info;
  }

  void _handleDanger(String danger) {
    // 处理危险生物
    switch (danger) {
      case 'wolf':
        widget.gameState.character['health'] -= 2;
        widget.gameState.addLog('遇到了一只狼，受到了伤害！');
        break;
      case 'bear':
        widget.gameState.character['health'] -= 4;
        widget.gameState.addLog('遇到了一只熊，受到了严重伤害！');
        break;
      case 'snake':
        widget.gameState.character['health'] -= 1;
        widget.gameState.addLog('被毒蛇咬伤了！');
        break;
      // 添加更多危险生物的处理...
    }

    // 检查生命值
    if (widget.gameState.character['health'] <= 0) {
      _showGameOverDialog();
    }
  }

  void _showNewLocationDialog(String location) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('发现新地点：${_locationInfo[location]['name']}'),
        content: Text(_locationInfo[location]['description']),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('游戏结束'),
        content: const Text('你的角色已经死亡。'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // 重置游戏状态
              widget.gameState.resetGame();
            },
            child: const Text('重新开始'),
          ),
        ],
      ),
    );
  }

  // 构建资源显示
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

  // 构建狩猎按钮
  Widget _buildHuntingButtons() {
    if (widget.gameState.isHunting) {
      return Column(
        children: [
          Text(
            '正在狩猎: ${widget.gameState.huntingOutcomes[widget.gameState.currentHuntType]!['name']}',
            style: const TextStyle(color: Colors.white),
          ),
          Text(
            '剩余时间: ${widget.gameState.huntingTimeLeft}秒',
            style: const TextStyle(color: Colors.white),
          ),
        ],
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: widget.gameState.huntingOutcomes.entries.map((entry) {
        String huntType = entry.key;
        Map<String, dynamic> config = entry.value;
        bool hasRequiredWeapons = true;

        if (config.containsKey('requires')) {
          var requires = config['requires'] as Map<String, int>;
          int weaponsLevel =
              widget.gameState.room['buildings']?['weapons'] ?? 0;
          hasRequiredWeapons = weaponsLevel >= (requires['weapons'] ?? 0);
        }

        return ElevatedButton(
          onPressed: hasRequiredWeapons
              ? () {
                  if (widget.gameState.startHunting(huntType)) {
                    _addLog('开始狩猎${config['name']}');
                  }
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey.shade800,
            disabledBackgroundColor: Colors.grey.shade900,
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.grey,
            minimumSize: const Size(120, 40),
          ),
          child: Text(
            config['name'] as String,
            style: const TextStyle(fontSize: 14),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGatheringButtons() {
    return Column(
      children: [
        ElevatedButton(
          onPressed: widget.gameState.isGatheringWater
              ? null
              : () => widget.gameState.gatherWater(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey.shade800,
            disabledBackgroundColor: Colors.grey.shade900,
          ),
          child: Text(
            widget.gameState.isGatheringWater ? '正在收集水...' : '收集水',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  // 修改主界面布局
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildResourceDisplay(),
                    const SizedBox(height: 16),
                    const Text(
                      '狩猎',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildHuntingButtons(),
                    const SizedBox(height: 16),
                    _buildGatheringButtons(),
                    _buildGameLog(),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade900),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      widget.gameState.currentLocation = 'room';
                      widget.gameState.notifyListeners();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade800,
                    ),
                    child: const Text(
                      '返回房间',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
