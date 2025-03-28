import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';
import '../../models/game_state.dart';
import '../../models/world_system.dart';
import '../../models/path_system.dart';
import '../../config/game_settings.dart';

class WorldScreen extends StatefulWidget {
  final GameState gameState;
  final PathSystem pathSystem;
  final WorldSystem worldSystem;

  const WorldScreen({
    super.key,
    required this.gameState,
    required this.pathSystem,
    required this.worldSystem,
  });

  @override
  State<WorldScreen> createState() => _WorldScreenState();
}

class _WorldScreenState extends State<WorldScreen> {
  // 瓦片颜色映射
  final Map<String, Color> tileColors = {
    ';': Colors.green.shade800, // 森林
    ',': Colors.green.shade400, // 田野
    '.': Colors.brown.shade300, // 荒地
    'A': Colors.red.shade500, // 村庄
    'I': Colors.grey.shade700, // 铁矿
    'C': Colors.black54, // 煤矿
    'S': Colors.yellow.shade700, // 硫矿
    'H': Colors.brown.shade700, // 房屋
    'V': Colors.grey.shade900, // 洞穴
    'O': Colors.blue.shade300, // 小镇
    'Y': Colors.blue.shade700, // 城市
    'P': Colors.orange, // 前哨
    'W': Colors.purple, // 飞船
    'B': Colors.red.shade700, // 钻孔
    'F': Colors.red.shade900, // 战场
    'M': Colors.teal.shade700, // 沼泽
    'U': Colors.amber, // 缓存
    'X': Colors.deepPurple, // 刽子手
  };

  // 添加游戏状态跟踪
  String _statusMessage = '';
  bool _canMove = true;
  bool _isLoading = true; // 添加加载状态标志
  int _lastPlayerX = -1; // 跟踪最后的玩家位置X
  int _lastPlayerY = -1; // 跟踪最后的玩家位置Y

  @override
  void initState() {
    super.initState();
    // 使用Future.delayed让界面有机会先渲染
    Future.microtask(() => _initWorldScreen());
  }

  // 初始化世界屏幕 - 异步处理以避免卡顿
  Future<void> _initWorldScreen() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 确保世界地图已初始化
      if (widget.worldSystem.map.isEmpty) {
        if (kDebugMode) {
          print('世界地图为空，初始化中...');
        }
        await Future.microtask(() => widget.worldSystem.init());
      } else {
        if (kDebugMode) {
          print(
              '地图已存在，大小: ${widget.worldSystem.map.length}x${widget.worldSystem.map[0].length}');
        }
      }

      // 确保玩家位置已设置
      if (widget.worldSystem.position.isEmpty) {
        if (kDebugMode) {
          print('玩家位置未设置，设置默认位置');
        }
        widget.worldSystem.position = [
          WorldSystem.villagePos[0],
          WorldSystem.villagePos[1]
        ];
      } else {
        if (kDebugMode) {
          print('玩家当前位置：${widget.worldSystem.position}');
        }
      }

      // 确保lastPosition已初始化
      if (widget.worldSystem.lastPosition.isEmpty) {
        widget.worldSystem.lastPosition =
            List.from(widget.worldSystem.position);
      }

      // 确保可见性掩码已初始化
      if (widget.worldSystem.mask.isEmpty &&
          widget.worldSystem.map.isNotEmpty) {
        if (kDebugMode) {
          print('更新可见性掩码');
        }
        await Future.microtask(() => widget.worldSystem.updateMask());
      }

      // 检查世界地图状态
      _validateWorldState();

      // 初始化玩家位置跟踪
      _lastPlayerX = widget.worldSystem.position[0];
      _lastPlayerY = widget.worldSystem.position[1];
    } catch (e) {
      if (kDebugMode) {
        print('初始化世界屏幕出错: $e');
      }
      _statusMessage = '初始化出错: $e';
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 验证世界状态
  void _validateWorldState() {
    try {
      if (widget.worldSystem.map.isEmpty) {
        _statusMessage = '地图未生成，请返回村庄';
        _canMove = false;
        return;
      }

      if (widget.worldSystem.position.isEmpty) {
        _statusMessage = '位置未初始化，请返回村庄';
        _canMove = false;
        return;
      }

      if (widget.worldSystem.water <= 0) {
        _statusMessage = '水已耗尽，无法继续移动';
        _canMove = false;
        return;
      }

      // 打印背包内容，用于调试
      if (kDebugMode) {
        print('验证食物状态:');
        print('背包内容: ${widget.pathSystem.outfit}');
        print('有食物: ${widget.pathSystem.hasFood() ? "是" : "否"}');
      }

      // 使用PathSystem的hasFood方法检查食物
      if (!widget.pathSystem.hasFood()) {
        _statusMessage = '食物已耗尽，无法继续移动';
        _canMove = false;
        return;
      }

      _statusMessage = '';
      _canMove = true;
    } catch (e) {
      if (kDebugMode) {
        print('验证世界状态出错: $e');
      }
      _statusMessage = '世界系统出错，请返回村庄';
      _canMove = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 如果正在加载，显示加载指示器
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                GameSettings.languageManager
                    .get('map_loading', category: 'world'),
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // 顶部状态栏
          _buildStatusBar(),

          // 状态信息（如果有）
          if (_statusMessage.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.red.shade900,
              width: double.infinity,
              child: Text(
                _statusMessage,
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),

          // 地图区域
          Expanded(
            child: Center(
              child: _buildMap(),
            ),
          ),

          // 底部控制栏
          _buildControlBar(),
        ],
      ),
    );
  }

  // 构建状态栏
  Widget _buildStatusBar() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.black54,
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 水资源
            _buildStatusItem(
              icon: Icons.water_drop,
              value: widget.worldSystem.water.toString(),
              color: Colors.blue,
            ),

            // 食物 (背包中的熏肉)
            _buildStatusItem(
              icon: Icons.fastfood,
              value: (widget.pathSystem.outfit['cured meat'] ?? 0).toString(),
              color: Colors.orange,
            ),

            // 指南针方向
            _buildStatusItem(
              icon: Icons.explore,
              value: widget.worldSystem.getCompassDirection(),
              color: Colors.amber,
            ),

            // 开发模式下显示补充资源按钮
            if (kDebugMode || GameSettings.devMode)
              IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.green),
                tooltip: '补充资源',
                onPressed: () => _refillResources(),
              ),

            // 开发模式下显示位置重置按钮
            if (kDebugMode || GameSettings.devMode)
              IconButton(
                icon:
                    const Icon(Icons.home_repair_service, color: Colors.purple),
                tooltip: '重置位置',
                onPressed: () => _resetPosition(),
              ),

            // 返回村庄按钮
            TextButton.icon(
              icon: const Icon(Icons.home, color: Colors.white),
              label: Text(
                  GameSettings.languageManager
                      .get('village', category: 'world'),
                  style: const TextStyle(color: Colors.white)),
              onPressed: () {
                widget.gameState.currentLocation = 'room';
                setState(() {
                  // Update state to trigger rebuild
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  // 构建状态项
  Widget _buildStatusItem({
    required IconData icon,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  // 构建地图
  Widget _buildMap() {
    if (widget.worldSystem.map.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
                GameSettings.languageManager
                    .get('map_loading', category: 'world'),
                style: const TextStyle(color: Colors.white)),
          ],
        ),
      );
    }

    // 计算可视区域大小 - 减小默认视野大小以提高性能
    int viewRadius = 10;

    // 开发模式下使用更大的视野
    if (kDebugMode || GameSettings.devMode) {
      viewRadius = 15;
    }

    int playerX = widget.worldSystem.position[0];
    int playerY = widget.worldSystem.position[1];

    int startX =
        (playerX - viewRadius).clamp(0, widget.worldSystem.map[0].length - 1);
    int endX =
        (playerX + viewRadius).clamp(0, widget.worldSystem.map[0].length - 1);
    int startY =
        (playerY - viewRadius).clamp(0, widget.worldSystem.map.length - 1);
    int endY =
        (playerY + viewRadius).clamp(0, widget.worldSystem.map.length - 1);

    // 创建可视区域的网格
    return LayoutBuilder(
      builder: (context, constraints) {
        // 固定单元格大小以减少计算量和重新布局
        double cellSize = 12.0;

        // 计算容器大小
        double containerWidth = (endX - startX + 1) * cellSize;
        double containerHeight = (endY - startY + 1) * cellSize;

        // 预先创建瓦片列表以避免在构建过程中创建过多小部件
        List<Widget> tiles = [];

        // 批量创建瓦片
        for (int y = startY; y <= endY; y++) {
          for (int x = startX; x <= endX; x++) {
            // 只渲染可见区域内的瓦片
            if (widget.worldSystem.mask[y][x]) {
              String tileChar = widget.worldSystem.map[y][x];
              Color tileColor = tileColors[tileChar] ?? Colors.grey;
              BorderRadius? borderRadius;

              // 村庄特殊标记
              if (tileChar == WorldSystem.tile['VILLAGE']) {
                borderRadius = BorderRadius.circular(cellSize / 2);
              }

              tiles.add(
                Positioned(
                  left: (x - startX) * cellSize,
                  top: (y - startY) * cellSize,
                  width: cellSize,
                  height: cellSize,
                  child: Container(
                    width: cellSize,
                    height: cellSize,
                    decoration: BoxDecoration(
                      color: tileColor,
                      borderRadius: borderRadius,
                    ),
                  ),
                ),
              );
            } else {
              // 对于未探索的区域，使用黑色块
              tiles.add(
                Positioned(
                  left: (x - startX) * cellSize,
                  top: (y - startY) * cellSize,
                  width: cellSize,
                  height: cellSize,
                  child: Container(
                    width: cellSize,
                    height: cellSize,
                    color: Colors.black,
                  ),
                ),
              );
            }
          }
        }

        // 添加玩家标记
        tiles.add(
          Positioned(
            left: (playerX - startX) * cellSize,
            top: (playerY - startY) * cellSize,
            width: cellSize,
            height: cellSize,
            child: Container(
              alignment: Alignment.center,
              child: Icon(
                Icons.person,
                color: Colors.white,
                size: cellSize * 0.7,
              ),
            ),
          ),
        );

        return SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: containerWidth,
              height: containerHeight,
              child: Stack(
                children: tiles,
              ),
            ),
          ),
        );
      },
    );
  }

  // 构建底部控制栏
  Widget _buildControlBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      color: Colors.black54,
      child: SafeArea(
        child: Column(
          children: [
            // 方向控制按钮
            _buildMovementControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildMovementControls() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildDirectionButton('north', Icons.arrow_upward),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildDirectionButton('west', Icons.arrow_back),
              const SizedBox(width: 50),
              _buildDirectionButton('east', Icons.arrow_forward),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildDirectionButton('south', Icons.arrow_downward),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDirectionButton(String direction, IconData icon) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ElevatedButton(
        onPressed: _canMove
            ? () {
                _move(direction);
              }
            : null,
        style: ElevatedButton.styleFrom(
          shape: const CircleBorder(),
          padding: const EdgeInsets.all(16),
        ),
        child: Icon(icon),
      ),
    );
  }

  // 补充资源方法
  void _refillResources() {
    // 重置资源
    widget.worldSystem.water = WorldSystem.baseWater;
    widget.pathSystem.increaseSupply('cured meat');
    widget.pathSystem.increaseSupply('cured meat');

    // 更新状态
    _validateWorldState();
    setState(() {});

    // 显示提示
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('资源已补充')));
  }

  // 重置位置方法
  void _resetPosition() {
    widget.worldSystem.position = [
      WorldSystem.villagePos[0],
      WorldSystem.villagePos[1]
    ];
    widget.worldSystem.lastPosition = List.from(widget.worldSystem.position);
    widget.worldSystem.updateMask();
    _validateWorldState();
    setState(() {});
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('位置已重置到村庄')));
  }

  // 移动方法优化
  void _move(String direction) {
    if (!_canMove) return;

    // 暂时禁用移动以防止快速连点
    setState(() {
      _canMove = false;
    });

    // 执行移动
    bool success =
        widget.worldSystem.move(direction, widget.pathSystem, widget.gameState);

    if (success) {
      // 检查玩家是否移动了位置
      bool positionChanged = _lastPlayerX != widget.worldSystem.position[0] ||
          _lastPlayerY != widget.worldSystem.position[1];

      // 如果玩家位置变化了，清除瓦片缓存
      if (positionChanged) {
        _lastPlayerX = widget.worldSystem.position[0];
        _lastPlayerY = widget.worldSystem.position[1];
      }

      // 检查世界状态
      _validateWorldState();
    } else {
      if (kDebugMode) {
        print('移动失败');
      }
    }

    // 重新启用移动
    setState(() {
      _canMove = true;
    });
  }
}

class NarrativeManager {
  final GameState gameState;

  // 添加位置事件映射
  final Map<String, dynamic> locationEvents = {
    'cave': {
      'title': '洞穴',
      'descriptions': ['一个黑暗的洞穴，墙壁上有奇怪的标记。', '潮湿的洞穴，有水滴从顶部落下。', '洞穴深处传来奇怪的声音。'],
      'events': [
        {
          'name': '发现矿物',
          'description': '你发现了一些珍贵的矿物。',
          'chance': 0.6,
          'outcome': {
            'resources': {'iron': 3, 'coal': 2}
          }
        },
        {
          'name': '遭遇生物',
          'description': '一个黑暗的生物从阴影中爬出。',
          'chance': 0.3,
          'outcome': {'combat': true, 'enemy': 'cave beast'}
        }
      ]
    },
    'forest': {
      'title': '森林',
      'descriptions': ['茂密的树林，充满了生命。', '阳光透过树叶洒落在地面上。', '森林里充满了野生动物的声音。'],
      'events': [
        {
          'name': '采集木材',
          'description': '你找到了一些可用的木材。',
          'chance': 0.7,
          'outcome': {
            'resources': {'wood': 5}
          }
        },
        {
          'name': '遭遇狼群',
          'description': '一群狼正在接近你。',
          'chance': 0.4,
          'outcome': {'combat': true, 'enemy': 'wolf'}
        }
      ]
    }
  };

  NarrativeManager(this.gameState);

  // 处理位置叙事
  Map<String, dynamic>? getLocationNarrative(String locationType) {
    if (!locationEvents.containsKey(locationType)) return null;

    var location = locationEvents[locationType]!;
    var descriptions = location['descriptions'] as List<String>;

    // 随机选择一个描述
    String description = descriptions[Random().nextInt(descriptions.length)];

    // 随机选择一个事件
    List<Map<String, dynamic>> events = location['events'];
    List<Map<String, dynamic>> possibleEvents = [];

    for (var event in events) {
      double chance = event['chance'];
      if (Random().nextDouble() <= chance) {
        possibleEvents.add(event);
      }
    }

    Map<String, dynamic>? selectedEvent;
    if (possibleEvents.isNotEmpty) {
      selectedEvent = possibleEvents[Random().nextInt(possibleEvents.length)];
    }

    return {
      'title': location['title'],
      'description': description,
      'event': selectedEvent,
    };
  }

  // 应用事件结果
  void applyEventOutcome(Map<String, dynamic> outcome) {
    // 添加资源
    if (outcome.containsKey('resources')) {
      Map<String, int> resources = outcome['resources'];
      resources.forEach((resource, amount) {
        gameState.addResource(resource, amount);
      });
    }

    // 处理战斗
    if (outcome.containsKey('combat') && outcome['combat'] == true) {
      if (outcome.containsKey('enemy')) {
        String enemyType = outcome['enemy'];
        gameState.combatSystem.startCombat(enemyType, gameState);
      }
    }

    // 添加任何其他效果
    if (outcome.containsKey('effects')) {
      Map<String, dynamic> effects = outcome['effects'];
      effects.forEach((key, value) {
        switch (key) {
          case 'happiness':
            gameState.population['happiness'] += value;
            break;
          case 'population':
            gameState.population['total'] += value;
            break;
          // 添加其他效果处理
        }
      });
    }
  }
}
