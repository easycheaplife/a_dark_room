import 'package:flutter/material.dart';
import '../../models/game_state.dart';
import '../../models/combat_system.dart';
import '../../config/game_settings.dart';
import 'dart:math';
import 'dart:async' show Timer;

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

class _OutsideScreenState extends State<OutsideScreen>
    with AutomaticKeepAliveClientMixin {
  // 确保页面状态保持，防止频繁重建
  @override
  bool get wantKeepAlive => true;

  // 持有本地状态，不依赖GameState自动更新
  final List<String> _logs = []; // 游戏日志
  Map<String, int> _resources = {}; // 资源
  bool _isExploring = false;
  bool _isScavenging = false;
  bool _isHunting = false;
  String _currentLocation = 'forest';
  List<String> _discoveredLocations = [];
  Map<String, dynamic> _locationInfo = {};

  // 计时器
  Timer? _explorationTimer;
  Timer? _scavengingTimer;
  bool _isInitialized = false;

  // 防止重复监听
  bool _listenerAttached = false;

  @override
  void initState() {
    super.initState();
    // 初始化时手动更新一次，然后不再自动更新
    if (!_isInitialized) {
      _manuallyUpdateState();
      _loadLocationData();
      _isInitialized = true;

      // 监听应用生命周期
      WidgetsBinding.instance.addObserver(
        LifecycleEventHandler(
          resumeCallBack: () async {
            if (mounted) _manuallyUpdateState();
            return;
          },
        ),
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 确保监听器只添加一次
    if (!_listenerAttached) {
      // 只监听位置变化
      widget.gameState.addListener(_handleGameStateChange);
      _listenerAttached = true;
    }
  }

  // 只在真正需要时更新页面
  void _handleGameStateChange() {
    if (widget.gameState.currentLocation == 'outside' && mounted) {
      _manuallyUpdateState();
    }
  }

  @override
  void dispose() {
    // 页面销毁时，取消所有计时器和监听
    _cancelAllTimers();
    if (_listenerAttached) {
      widget.gameState.removeListener(_handleGameStateChange);
      _listenerAttached = false;
    }
    WidgetsBinding.instance.removeObserver(
      LifecycleEventHandler(resumeCallBack: () async => null),
    );
    super.dispose();
  }

  // 取消所有计时器
  void _cancelAllTimers() {
    _explorationTimer?.cancel();
    _scavengingTimer?.cancel();
    _explorationTimer = null;
    _scavengingTimer = null;
  }

  // 手动更新状态而不是依赖监听器
  void _manuallyUpdateState() {
    if (!mounted) return;

    setState(() {
      _resources = Map<String, int>.from(widget.gameState.resources);
    });
  }

  // 添加日志
  void _addLog(String message) {
    if (mounted) {
      setState(() {
        _logs.add(message);
        // 保持日志不超过10条
        if (_logs.length > 10) {
          _logs.removeAt(0);
        }
      });
    }
  }

  void _loadLocationData() {
    // 深拷贝已发现的位置，避免引用问题
    _discoveredLocations =
        List<String>.from(widget.gameState.world['discovered_locations'] ?? []);

    // 确保location_info不为空
    if (widget.gameState.world['location_info'] == null) {
      widget.gameState.world['location_info'] = {};
    }

    // 深拷贝位置信息，避免引用问题
    _locationInfo = Map<String, dynamic>.from(
        widget.gameState.world['location_info'] ?? {});

    // 如果没有发现任何位置，添加默认的森林
    if (_discoveredLocations.isEmpty) {
      _discoveredLocations.add('forest');
      // 直接使用预定义的位置配置
      _locationInfo['forest'] = GameSettings.locationConfigs['forest'] ??
          {
            'name': GameSettings.languageManager
                .get('forest', category: 'locations'),
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
    // 更新世界状态但不触发全局刷新
    widget.gameState.world['discovered_locations'] =
        List<String>.from(_discoveredLocations);
    widget.gameState.world['location_info'] =
        Map<String, dynamic>.from(_locationInfo);
  }

  void _startExploring() {
    if (_isExploring) return;

    // 取消任何现有计时器
    _cancelAllTimers();

    // 设置探索状态
    setState(() {
      _isExploring = true;
    });

    // 添加日志
    _addLog(
        '${GameSettings.languageManager.get('exploring_in', category: 'locations')} ${_locationInfo[_currentLocation]['name']}...');

    // 获取探索时间
    final explorationTime =
        _locationInfo[_currentLocation]?['exploration_time'] ?? 30;

    // 开发模式下使用短时间测试
    final actualTime = GameSettings.devMode ? 3 : explorationTime;

    // 创建计时器，只在完成时更新UI
    _explorationTimer = Timer(Duration(seconds: actualTime), () {
      // 安全检查
      if (!mounted) return;

      // 更新状态为不再探索
      setState(() {
        _isExploring = false;
      });

      // 执行探索完成逻辑
      _completeExploration();
    });
  }

  void _startScavenging() {
    if (_isScavenging) return;

    // 取消任何现有计时器
    _cancelAllTimers();

    // 设置搜寻状态
    setState(() {
      _isScavenging = true;
    });

    // 添加日志
    _addLog(
        '${GameSettings.languageManager.get('scavenging_in', category: 'locations')} ${_locationInfo[_currentLocation]['name']}...');

    // 创建计时器，但不更新UI，只在完成时更新
    final scavengingTime =
        _locationInfo[_currentLocation]?['scavenging_time'] ?? 20;
    _scavengingTimer = Timer(Duration(seconds: scavengingTime), () {
      if (!mounted) return;

      setState(() {
        _isScavenging = false;
      });

      _completeScavenging();
    });
  }

  void _startHunting(String type) {
    if (_isHunting) return;

    // 取消任何现有计时器
    _cancelAllTimers();

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

    // 设置狩猎状态
    setState(() {
      _isHunting = true;
    });

    // 开始战斗
    if (widget.gameState.combatSystem.startCombat(enemyId, widget.gameState)) {
      // 获取敌人名称
      String enemyName = GameSettings.languageManager.get(
          widget.gameState.combatSystem.enemies[enemyId]!.id,
          category: 'combat');
      String encounterMessage = GameSettings.languageManager
          .get('encountered', category: 'combat')
          .replaceAll('%s', enemyName);
      _addLog(encounterMessage);
    }
  }

  void _completeExploration() {
    // 随机发现新位置
    if (Random().nextDouble() < 0.3) {
      // 30%的概率发现新位置
      String newLocation = _generateNewLocation();
      if (newLocation.isNotEmpty) {
        // 使用setState更新UI
        setState(() {
          _discoveredLocations.add(newLocation);
          _locationInfo[newLocation] = _generateLocationInfo(newLocation);
        });

        // 保存发现到世界状态
        _updateWorldState();

        // 添加日志并显示对话框
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
    // 获取当前位置可获得的资源
    List<String> availableResources =
        _locationInfo[_currentLocation]?['resources'] ?? [];
    if (availableResources.isNotEmpty) {
      String resource =
          availableResources[Random().nextInt(availableResources.length)];
      int amount = Random().nextInt(3) + 1;

      // 添加资源
      widget.gameState.addResource(resource, amount);

      // 手动更新本地资源状态
      _manuallyUpdateState();

      _addLog(
          '在${_locationInfo[_currentLocation]['name']}中找到了 $amount 个 $resource');
    } else {
      _addLog('搜索完成，但没有找到任何资源。');
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

  // 显示战斗结果对话框
  void _showCombatResultDialog(bool victory, String loot, String enemyName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey.shade900,
          title: Text(
            victory
                ? GameSettings.languageManager
                    .get('victory', category: 'combat')
                : GameSettings.languageManager
                    .get('defeat', category: 'combat'),
            style: TextStyle(
              color: victory ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${GameSettings.languageManager.get('encountered', category: 'combat').replaceFirst('%s', enemyName)}',
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              if (victory && loot.isNotEmpty) ...[
                Text(
                  GameSettings.languageManager
                      .get('loot_gained', category: 'combat'),
                  style: const TextStyle(
                    color: Colors.yellow,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  loot,
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                GameSettings.languageManager
                    .get('continue', category: 'common'),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
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
    if (widget.gameState.combatSystem.isInCombat && _isHunting) {
      return _buildCombatScreen();
    }

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
            _buildWorkersDisplay(),
          ],
          const SizedBox(height: 16),
          _buildGameLog(),
          const SizedBox(height: 16),
          _buildActionButtons(),
        ],
      ),
    );
  }

  // 构建工人显示
  Widget _buildWorkersDisplay() {
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
            GameSettings.languageManager.get('worker_status', category: 'room'),
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
              // 探索按钮 - 无倒计时显示
              ElevatedButton(
                onPressed: _isExploring ? null : _startExploring,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade800,
                  disabledBackgroundColor: Colors.grey.shade900,
                ),
                child: Text(
                  _isExploring
                      ? GameSettings.languageManager
                          .get('exploring', category: 'actions')
                      : GameSettings.languageManager
                          .get('explore', category: 'actions'),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              // 搜索按钮 - 无倒计时显示
              ElevatedButton(
                onPressed: _isScavenging ? null : _startScavenging,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade800,
                  disabledBackgroundColor: Colors.grey.shade900,
                ),
                child: Text(
                  _isScavenging
                      ? GameSettings.languageManager
                          .get('scavenging', category: 'actions')
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
                    : () {
                        widget.gameState.gatherWater();
                        // 手动更新状态
                        _manuallyUpdateState();
                      },
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
              _buildReturnRoomButton(),
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
                        if (selected && _currentLocation != loc) {
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

    String enemyName =
        GameSettings.languageManager.get(enemy.id, category: 'combat');

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
                  // 执行战斗回合
                  Map<String, dynamic> result = widget.gameState.combatSystem
                      .executeCombatTurn(widget.gameState);

                  if (result['success']) {
                    _addLog(result['message']);

                    if (result.containsKey('victory')) {
                      bool victory = result['victory'];
                      String lootInfo = '';

                      if (victory) {
                        // 记录战利品信息
                        _addLog(
                            '${GameSettings.languageManager.get('victory', category: 'combat')} ${GameSettings.languageManager.get('loot_gained', category: 'combat')}');

                        (result['loot'] as Map<String, int>)
                            .forEach((resource, amount) {
                          _addLog(
                              '${GameSettings.languageManager.get(resource, category: 'resources')}: $amount');
                          lootInfo +=
                              '${GameSettings.languageManager.get(resource, category: 'resources')}: $amount\n';
                        });

                        if (result.containsKey('experience')) {
                          _addLog(
                              '${GameSettings.languageManager.get('experience_gained', category: 'combat')} ${result['experience']}');
                          lootInfo +=
                              '${GameSettings.languageManager.get('experience_gained', category: 'combat')} ${result['experience']}';
                        }

                        // 手动更新资源状态
                        _manuallyUpdateState();
                      } else {
                        // 失败
                        _addLog(GameSettings.languageManager
                            .get('defeat', category: 'combat'));
                      }

                      // 更新战斗状态
                      setState(() {
                        _isHunting = false;
                      });

                      // 显示战斗结果
                      _showCombatResultDialog(victory, lootInfo, enemy.name);
                    }
                  } else {
                    _addLog(result['message']);
                  }

                  // 更新UI
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
                  // 逃跑
                  widget.gameState.combatSystem.dispose();
                  setState(() {
                    _isHunting = false;
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

  // 返回房间按钮 - 优化切换
  Widget _buildReturnRoomButton() {
    return ElevatedButton(
      onPressed: () {
        // 取消所有计时器
        _cancelAllTimers();
        // 先保存状态再切换
        _updateWorldState();

        // 使用异步切换以避免重建过程中的卡顿
        Future.microtask(() {
          widget.gameState.currentLocation = 'room';
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey.shade800,
      ),
      child: Text(
          GameSettings.languageManager.get('return_room', category: 'actions')),
    );
  }

  // 添加对热重载的支持
  @override
  void reassemble() {
    super.reassemble();
    _manuallyUpdateState();
  }

  @override
  Widget build(BuildContext context) {
    // 使用RepaintBoundary减少重绘
    return RepaintBoundary(
      child: Scaffold(
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
                  _cancelAllTimers();
                  widget.gameState.currentLocation = 'room';
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
                    _cancelAllTimers();
                    widget.gameState.currentLocation = 'store';
                  }),
                // 制作
                if (widget.gameState.craftingUnlocked)
                  _buildNavButton(
                      GameSettings.languageManager
                          .get('craft_btn', category: 'navigation'), () {
                    _cancelAllTimers();
                    widget.gameState.currentLocation = 'crafting';
                  }),
              ],
            ),
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

// 生命周期事件处理器
class LifecycleEventHandler extends WidgetsBindingObserver {
  final Future<void> Function() resumeCallBack;

  LifecycleEventHandler({
    required this.resumeCallBack,
  });

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      await resumeCallBack();
    }
  }
}
