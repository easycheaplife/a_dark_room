import 'package:flutter/material.dart';
import '../../models/game_state.dart';
import '../../models/combat_system.dart';
import '../../config/game_settings.dart';
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
  String _currentHuntType = '';

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
        'name':
            GameSettings.languageManager.get('forest', category: 'locations'),
        'description': GameSettings.languageManager
            .get('forest_desc', category: 'locations'),
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

    _addLog(
        '${GameSettings.languageManager.get('exploring_in', category: 'locations')} ${_locationInfo[_currentLocation]['name']}...');
    _explorationTimer();
  }

  void _startScavenging() {
    if (_isScavenging) return;

    setState(() {
      _isScavenging = true;
      _scavengingTimeLeft =
          _locationInfo[_currentLocation]?['scavenging_time'] ?? 20;
    });

    _addLog(
        '${GameSettings.languageManager.get('scavenging_in', category: 'locations')} ${_locationInfo[_currentLocation]['name']}...');
    _scavengingTimer();
  }

  void _startHunting(String type) {
    if (_isHunting) return;

    setState(() {
      _isHunting = true;
      _currentHuntType = type;
    });

    String enemyId;
    switch (type) {
      case 'small':
        enemyId = 'wolf';
        break;
      case 'large':
        enemyId = Random().nextBool() ? 'bear' : 'bandit';
        break;
      default:
        return;
    }

    if (widget.gameState.combatSystem.startCombat(enemyId, widget.gameState)) {
      // Get the translated enemy name
      String enemyName = GameSettings.languageManager.get(
          widget.gameState.combatSystem.enemies[enemyId]!.id,
          category: 'combat');
      // Get the translated encounter message with enemy name
      String encounterMessage = GameSettings.languageManager
          .get('encountered', category: 'combat')
          .replaceAll('%s', enemyName);
      _addLog(encounterMessage);
    }
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
        _addLog('探索发现了一个新的地点：${_locationInfo[newLocation]['name']}');
        _showNewLocationDialog(newLocation);
      } else {
        _addLog('探索完成，但没有发现新的地点。');
      }
    } else {
      _addLog('探索完成，但没有发现新的地点。');
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
      _addLog(
          '在${_locationInfo[_currentLocation]['name']}中找到了 $amount 个 $resource');
    } else {
      _addLog('搜索完成，但没有找到任何资源。');
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
    // 过滤掉已发现的位置
    List<String> possibleLocations = List.from(GameSettings.possibleLocations);
    possibleLocations.removeWhere((loc) => _discoveredLocations.contains(loc));
    if (possibleLocations.isEmpty) return '';

    return possibleLocations[Random().nextInt(possibleLocations.length)];
  }

  Map<String, dynamic> _generateLocationInfo(String location) {
    return GameSettings.locationConfigs[location]!;
  }

  void _handleDanger(String danger) {
    if (widget.gameState.startCombat(danger)) {
      _showCombatDialog();
    }
  }

  void _showCombatDialog() {
    String enemyId = widget.gameState.combat['current_enemy'];
    Map<String, dynamic> enemy = widget.gameState.enemies[enemyId]!;

    // Get the translated enemy name
    String enemyName = GameSettings.languageManager
        .get(enemy['name_key'] ?? enemyId, category: 'combat');

    // Format health and turns strings with proper translations
    String enemyHealthText = GameSettings.languageManager
        .get('enemy_health_fraction', category: 'combat')
        .replaceFirst('%d', '${enemy['health']}')
        .replaceFirst('%d', '${enemy['health']}');

    String playerHealthText = GameSettings.languageManager
        .get('player_health_fraction', category: 'combat')
        .replaceFirst('%d', '${widget.gameState.combat['player_health']}')
        .replaceFirst('%d', '${widget.gameState.combat['player_max_health']}');

    String turnsLeftText = GameSettings.languageManager
        .get('turns_left_value', category: 'combat')
        .replaceFirst('%d', '${widget.gameState.combat['combat_round']}');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: Text(
          '${GameSettings.languageManager.get('combat_title', category: 'combat')}$enemyName',
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              enemyHealthText,
              style: const TextStyle(color: Colors.white),
            ),
            Text(
              playerHealthText,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              turnsLeftText,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Map<String, dynamic> result = widget.gameState.attack();
              if (!result['success']) {
                Navigator.of(context).pop();
                if (result['message'].contains('杀死了')) {
                  _showGameOverDialog();
                }
              } else {
                Navigator.of(context).pop();
                _showCombatDialog();
              }
            },
            child: Text(
                GameSettings.languageManager.get('attack', category: 'combat')),
          ),
          TextButton(
            onPressed: () {
              widget.gameState.flee();
              Navigator.of(context).pop();
            },
            child: Text(
                GameSettings.languageManager.get('flee', category: 'combat')),
          ),
        ],
      ),
    );
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

  // 构建资源栏
  Widget _buildResourceBar() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.brown.shade800,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildResourceItem('wood', Icons.forest),
          _buildResourceItem('meat', Icons.restaurant),
          _buildResourceItem('fur', Icons.pets),
          _buildResourceItem('water', Icons.water_drop),
        ],
      ),
    );
  }

  // 构建资源项
  Widget _buildResourceItem(String resource, IconData icon) {
    return Tooltip(
      message:
          GameSettings.languageManager.get(resource, category: 'resources'),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 4),
          Text(
            '${_resources[resource] ?? 0}',
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  // 构建内容区域
  Widget _buildContentArea() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isHunting && widget.gameState.combatSystem.isInCombat)
            _buildCombatScreen(),
          if (!_isHunting) ...[
            _buildLocationSelector(),
            const SizedBox(height: 16),
            _buildResourceDisplay(),
            const SizedBox(height: 16),
            // 添加工人状态显示
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
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
                        GameSettings.languageManager
                            .get('worker_status', category: 'room'),
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '${GameSettings.languageManager.get('gatherer', category: 'villagers')}: 5',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '${GameSettings.languageManager.get('hunter', category: 'villagers')}: 3',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '${GameSettings.languageManager.get('builder', category: 'villagers')}: 2',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          _buildGameLog(),
          const SizedBox(height: 16),
          _buildActionButtons(),
        ],
      ),
    );
  }

  // 构建资源显示
  Widget _buildResourceDisplay() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        border: Border.all(color: Colors.grey.shade800),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: GameSettings.resourceGroups.entries.map((group) {
          final resources = group.value
              .where((resource) => (_resources[resource] ?? 0) > 0)
              .toList();

          if (resources.isEmpty) return const SizedBox.shrink();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                GameSettings.languageManager
                    .get(group.key, category: 'resource_groups'),
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
                    message:
                        '${GameSettings.languageManager.get(resource, category: 'resources')}: $amount/$limit',
                    child: Text(
                      '${GameSettings.languageManager.get(resource, category: 'resources')}: $amount',
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
    if (_logs.isEmpty) {
      return const SizedBox.shrink();
    }

    // 创建一个ScrollController来控制滚动
    final ScrollController scrollController = ScrollController();

    // 使用Future.delayed来确保在构建完成后滚动到底部
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

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
          controller: scrollController,
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
    if (_isHunting && widget.gameState.combatSystem.isInCombat) {
      return const SizedBox.shrink(); // 战斗时不显示其他按钮
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              // 探索按钮
              ElevatedButton(
                onPressed: _isExploring ? null : _startExploring,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade800,
                  disabledBackgroundColor: Colors.grey.shade900,
                ),
                child: Text(
                  _isExploring
                      ? '${GameSettings.languageManager.get('exploring', category: 'actions')}... $_explorationTimeLeft${GameSettings.languageManager.get('seconds', category: 'common')}'
                      : GameSettings.languageManager
                          .get('explore', category: 'actions'),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              // 搜索按钮
              ElevatedButton(
                onPressed: _isScavenging ? null : _startScavenging,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade800,
                  disabledBackgroundColor: Colors.grey.shade900,
                ),
                child: Text(
                  _isScavenging
                      ? '${GameSettings.languageManager.get('scavenging', category: 'actions')}... $_scavengingTimeLeft${GameSettings.languageManager.get('seconds', category: 'common')}'
                      : GameSettings.languageManager
                          .get('scavenge', category: 'actions'),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              // 狩猎按钮
              if (!_isHunting) ...[
                ElevatedButton(
                  onPressed: () => _startHunting('small'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade800,
                  ),
                  child: Text(GameSettings.languageManager
                      .get('small_hunt', category: 'combat')),
                ),
                ElevatedButton(
                  onPressed: () => _startHunting('large'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade800,
                  ),
                  child: Text(GameSettings.languageManager
                      .get('large_hunt', category: 'combat')),
                ),
              ],
              // 收集水按钮
              ElevatedButton(
                onPressed: widget.gameState.isGatheringWater
                    ? null
                    : () => widget.gameState.gatherWater(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade800,
                  disabledBackgroundColor: Colors.grey.shade900,
                ),
                child: Text(
                  widget.gameState.isGatheringWater
                      ? GameSettings.languageManager
                          .get('gathering_water', category: 'actions')
                      : GameSettings.languageManager
                          .get('gather_water', category: 'actions'),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              // 返回房间按钮
              ElevatedButton(
                onPressed: () {
                  widget.gameState.currentLocation = 'room';
                  widget.gameState.notifyListeners();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade800,
                ),
                child: Text(GameSettings.languageManager
                    .get('return_room', category: 'actions')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 构建位置选择器
  Widget _buildLocationSelector() {
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
            '${GameSettings.languageManager.get('current_location', category: 'locations')}: ${_locationInfo[_currentLocation]?["name"] ?? GameSettings.languageManager.get('unknown', category: 'common')}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _locationInfo[_currentLocation]?["description"] ?? "",
            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _discoveredLocations
                .map((loc) => ChoiceChip(
                      label: Text(_locationInfo[loc]?["name"] ?? loc),
                      selected: _currentLocation == loc,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _currentLocation = loc;
                          });
                        }
                      },
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  // 构建战斗界面
  Widget _buildCombatScreen() {
    final combatState = widget.gameState.combatSystem.getCombatState();
    final enemy = combatState['currentEnemy'] as Enemy;
    final playerHealth = combatState['playerHealth'] as int;
    final enemyHealth = combatState['enemyHealth'] as int;
    final turnsLeft = combatState['turnsLeft'] as int;

    // Get enemy name translation
    String enemyName =
        GameSettings.languageManager.get(enemy.id, category: 'combat');

    // Get formatted health and turns text
    String enemyHealthText = GameSettings.languageManager
        .get('enemy_health_fraction', category: 'combat')
        .replaceFirst('%d', '$enemyHealth')
        .replaceFirst('%d', '${enemy.health}');

    String playerHealthText = GameSettings.languageManager
        .get('player_health_fraction', category: 'combat')
        .replaceFirst('%d', '$playerHealth')
        .replaceFirst('%d', '100');

    String turnsLeftText = GameSettings.languageManager
        .get('turns_left_value', category: 'combat')
        .replaceFirst('%d', '$turnsLeft');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        border: Border.all(color: Colors.grey.shade800),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${GameSettings.languageManager.get('combat_title', category: 'combat')}$enemyName',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            enemyHealthText,
            style: const TextStyle(color: Colors.white),
          ),
          Text(
            playerHealthText,
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            turnsLeftText,
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () {
                  Map<String, dynamic> result = widget.gameState.combatSystem
                      .executeCombatTurn(widget.gameState);
                  if (result['success']) {
                    _addLog(result['message']);
                    if (result.containsKey('victory')) {
                      // 战斗结束
                      if (result['victory']) {
                        _addLog(
                            '${GameSettings.languageManager.get('victory', category: 'combat')} ${GameSettings.languageManager.get('loot_gained', category: 'combat')}');
                        (result['loot'] as Map<String, int>)
                            .forEach((resource, amount) {
                          _addLog(
                              '${GameSettings.languageManager.get(resource, category: 'resources')}: $amount');
                        });
                        if (result.containsKey('experience')) {
                          _addLog(
                              '${GameSettings.languageManager.get('experience_gained', category: 'combat')} ${result['experience']}');
                        }
                      } else {
                        _addLog(GameSettings.languageManager
                            .get('defeat', category: 'combat'));
                      }
                      setState(() {
                        _isHunting = false;
                        _currentHuntType = '';
                      });
                    }
                  } else {
                    _addLog(result['message']);
                  }
                  setState(() {});
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  minimumSize: const Size(100, 40),
                ),
                child: Text(GameSettings.languageManager
                    .get('attack', category: 'combat')),
              ),
              ElevatedButton(
                onPressed: () {
                  widget.gameState.combatSystem.dispose();
                  setState(() {
                    _isHunting = false;
                    _currentHuntType = '';
                  });
                  _addLog(GameSettings.languageManager
                      .get('fled_combat', category: 'combat'));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  minimumSize: const Size(100, 40),
                ),
                child: Text(GameSettings.languageManager
                    .get('flee', category: 'combat')),
              ),
            ],
          ),
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
            // 资源栏
            _buildResourceBar(),
            // 内容区域
            Expanded(
              child: _buildContentArea(),
            ),
          ],
        ),
      ),
      // 底部导航栏，显示不同场景的按钮
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border(
            top: BorderSide(color: Colors.grey.shade800, width: 1),
          ),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildNavButton(
                  GameSettings.languageManager
                      .get('room_btn', category: 'navigation'), () {
                // 前往小屋
                widget.gameState.currentLocation = 'room';
                widget.gameState.notifyListeners();
              }),
              _buildNavButton(
                  GameSettings.languageManager
                      .get('hunt_btn', category: 'navigation'), () {
                // 狩猎
                _startHunting('small');
              }),
              // 交易站
              if (widget.gameState.storeOpened)
                _buildNavButton(
                    GameSettings.languageManager
                        .get('store_btn', category: 'navigation'), () {
                  widget.gameState.currentLocation = 'store';
                  widget.gameState.notifyListeners();
                }),
              // 制作
              if (widget.gameState.craftingUnlocked)
                _buildNavButton(
                    GameSettings.languageManager
                        .get('craft_btn', category: 'navigation'), () {
                  widget.gameState.currentLocation = 'crafting';
                  widget.gameState.notifyListeners();
                }),
            ],
          ),
        ),
      ),
    );
  }

  // 构建导航按钮
  Widget _buildNavButton(String label, VoidCallback onPressed) {
    return Container(
      width: 50,
      height: 50,
      margin: const EdgeInsets.all(5),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey.shade800,
          padding: EdgeInsets.zero,
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
