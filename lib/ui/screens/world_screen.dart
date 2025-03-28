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

  @override
  void initState() {
    super.initState();
    // 确保世界地图已初始化
    if (widget.worldSystem.map.isEmpty) {
      if (kDebugMode) {
        print('世界地图为空，初始化中...');
      }
      widget.worldSystem.init();
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
    }

    // 确保可见性掩码已初始化
    if (widget.worldSystem.mask.isEmpty && widget.worldSystem.map.isNotEmpty) {
      if (kDebugMode) {
        print('更新可见性掩码');
      }
      widget.worldSystem.updateMask();
    }

    // 检查世界地图状态
    _validateWorldState();
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

    // 计算可视区域大小
    int viewRadius = 15; // 增加地图可视半径

    // 开发模式下使用更大的视野
    if (kDebugMode || GameSettings.devMode) {
      viewRadius = 20;
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
        double cellSize = min(
          constraints.maxWidth / (endX - startX + 1),
          constraints.maxHeight / (endY - startY + 1),
        );

        // 最小和最大单元格大小限制
        cellSize = cellSize.clamp(8.0, 40.0);

        return SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: (endX - startX + 1) * cellSize,
              height: (endY - startY + 1) * cellSize,
              child: Stack(
                children: [
                  // 绘制地图网格
                  for (int y = startY; y <= endY; y++)
                    for (int x = startX; x <= endX; x++)
                      Positioned(
                        left: (x - startX) * cellSize,
                        top: (y - startY) * cellSize,
                        width: cellSize,
                        height: cellSize,
                        child: _buildTile(x, y, cellSize),
                      ),

                  // 在最上层绘制玩家位置标记
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
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTile(int x, int y, double cellSize) {
    // Get the current player position to calculate tile position
    int playerX = widget.worldSystem.position[0];
    int playerY = widget.worldSystem.position[1];

    // Calculate the start coordinates based on viewRadius (same as in _buildMap)
    int viewRadius = 5;
    if (kDebugMode || GameSettings.devMode) {
      viewRadius = 20;
    }

    int startX =
        (playerX - viewRadius).clamp(0, widget.worldSystem.map[0].length - 1);
    int startY =
        (playerY - viewRadius).clamp(0, widget.worldSystem.map.length - 1);

    String tile = widget.worldSystem.map[y][x];

    // 只显示已探索区域
    if (!widget.worldSystem.mask[y][x]) {
      return Positioned(
        left: (x - startX) * cellSize,
        top: (y - startY) * cellSize,
        width: cellSize,
        height: cellSize,
        child: Container(
          width: cellSize,
          height: cellSize,
          color: Colors.black,
        ),
      );
    }

    // 更好的视觉区分
    Color tileColor = tileColors[tile] ?? Colors.grey;
    BorderRadius? borderRadius;

    // 村庄特殊标记
    if (tile == WorldSystem.tile['VILLAGE']) {
      borderRadius = BorderRadius.circular(cellSize / 2);
    }

    return Positioned(
      left: (x - startX) * cellSize,
      top: (y - startY) * cellSize,
      width: cellSize,
      height: cellSize,
      child: Stack(
        children: [
          Container(
            width: cellSize,
            height: cellSize,
            decoration: BoxDecoration(
              color: tileColor,
              borderRadius: borderRadius,
            ),
          ),
        ],
      ),
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

  // 移动方法
  void _move(String direction) {
    if (!_canMove) return;

    if (kDebugMode) {
      print('尝试移动: $direction');
      print(
          '移动前地块: ${widget.worldSystem.map[widget.worldSystem.position[1]][widget.worldSystem.position[0]]}');
    }

    bool moved =
        widget.worldSystem.move(direction, widget.pathSystem, widget.gameState);

    if (moved) {
      if (kDebugMode) {
        print('移动成功!');
        print(
            '当前地块: ${widget.worldSystem.map[widget.worldSystem.position[1]][widget.worldSystem.position[0]]}');
      }

      // 重新验证世界状态
      _validateWorldState();

      // 如果触发了事件，更新UI
      if (widget.gameState.currentEvent != null) {
        setState(() {
          _canMove = false;
        });
      }
    } else {
      // 移动失败
      if (kDebugMode) {
        print('移动失败');
      }
    }

    // 刷新界面
    setState(() {});
  }
}
