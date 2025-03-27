import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../models/game_state.dart';
import '../../models/path_system.dart';
import '../../models/world_system.dart';
import '../../config/game_settings.dart';

class WorldScreen extends StatefulWidget {
  final GameState gameState;
  final PathSystem pathSystem;
  final WorldSystem worldSystem;

  const WorldScreen({
    Key? key,
    required this.gameState,
    required this.pathSystem,
    required this.worldSystem,
  }) : super(key: key);

  @override
  State<WorldScreen> createState() => _WorldScreenState();
}

class _WorldScreenState extends State<WorldScreen> {
  // 瓦片大小
  static const double tileSize = 20.0;

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
    // 确保世界系统已初始化
    if (widget.worldSystem.map.isEmpty) {
      if (kDebugMode) {
        print('世界地图为空，初始化中...');
      }
      widget.worldSystem.init();
    }

    // 确保玩家位置已设置
    if (widget.worldSystem.position == null) {
      if (kDebugMode) {
        print('玩家位置未设置，设置默认位置');
      }
      widget.worldSystem.position = [
        WorldSystem.VILLAGE_POS[0],
        WorldSystem.VILLAGE_POS[1]
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

      if (widget.worldSystem.position == null) {
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

  // 显示消息方法
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
            if (kDebugMode || GameSettings.DEV_MODE)
              IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.green),
                tooltip: '补充资源',
                onPressed: () => _refillResources(),
              ),

            // 开发模式下显示位置重置按钮
            if (kDebugMode || GameSettings.DEV_MODE)
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
                widget.gameState.notifyListeners();
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
    if (kDebugMode || GameSettings.DEV_MODE) {
      viewRadius = 20;
    }

    int playerX = widget.worldSystem.position![0];
    int playerY = widget.worldSystem.position![1];

    int startX =
        (playerX - viewRadius).clamp(0, widget.worldSystem.map[0].length - 1);
    int endX =
        (playerX + viewRadius).clamp(0, widget.worldSystem.map[0].length - 1);
    int startY =
        (playerY - viewRadius).clamp(0, widget.worldSystem.map.length - 1);
    int endY =
        (playerY + viewRadius).clamp(0, widget.worldSystem.map.length - 1);

    // 创建可视区域的网格
    return InteractiveViewer(
      constrained: false,
      boundaryMargin: const EdgeInsets.all(200),
      minScale: 0.5,
      maxScale: 3.0,
      child: Container(
        width: (endX - startX + 1) * tileSize,
        height: (endY - startY + 1) * tileSize,
        color: Colors.black,
        child: Stack(
          children: [
            // 渲染地图瓦片
            ...List.generate(endY - startY + 1, (y) {
              return List.generate(endX - startX + 1, (x) {
                int mapX = startX + x;
                int mapY = startY + y;

                String tile = widget.worldSystem.map[mapY][mapX];

                // 只显示已探索区域
                if (!widget.worldSystem.mask[mapY][mapX]) {
                  return Positioned(
                    left: x * tileSize,
                    top: y * tileSize,
                    child: Container(
                      width: tileSize,
                      height: tileSize,
                      color: Colors.black,
                    ),
                  );
                }

                // 更好的视觉区分
                Color tileColor = tileColors[tile] ?? Colors.grey;
                BorderRadius? borderRadius;

                // 村庄特殊标记
                if (tile == WorldSystem.TILE['VILLAGE']) {
                  borderRadius = BorderRadius.circular(tileSize / 2);
                }

                return Positioned(
                  left: x * tileSize,
                  top: y * tileSize,
                  child: Stack(
                    children: [
                      Container(
                        width: tileSize,
                        height: tileSize,
                        decoration: BoxDecoration(
                          color: tileColor,
                          borderRadius: borderRadius,
                        ),
                      ),
                      if (mapX == playerX && mapY == playerY)
                        Container(
                          width: tileSize,
                          height: tileSize,
                          alignment: Alignment.center,
                          child: Container(
                            width: tileSize * 0.9,
                            height: tileSize * 0.9,
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.7),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.person,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              });
            }).expand((widgets) => widgets).toList(),
          ],
        ),
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
                if (kDebugMode) {
                  print('尝试向$direction方向移动');
                  print('移动前位置: ${widget.worldSystem.position}');
                  print(
                      '移动前水量: ${widget.worldSystem.water}, 移动步数: ${widget.worldSystem.moves}');
                  print(
                      '移动前地块: ${widget.worldSystem.map[widget.worldSystem.position![1]][widget.worldSystem.position![0]]}');
                  print('移动前location: ${widget.gameState.currentLocation}');
                }

                if (widget.worldSystem
                    .move(direction, widget.pathSystem, widget.gameState)) {
                  if (kDebugMode) {
                    print('移动成功');
                    print('移动后位置: ${widget.worldSystem.position}');
                    print(
                        '移动后水量: ${widget.worldSystem.water}, 移动步数: ${widget.worldSystem.moves}');
                    print(
                        '当前地块: ${widget.worldSystem.map[widget.worldSystem.position![1]][widget.worldSystem.position![0]]}');
                    print('移动后location: ${widget.gameState.currentLocation}');
                  }

                  _validateWorldState();
                  setState(() {});
                } else {
                  if (kDebugMode) {
                    print('移动失败');
                  }
                }
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
    // 补充水资源
    widget.worldSystem.water = WorldSystem.BASE_WATER;

    // 补充食物
    if (!widget.pathSystem.outfit.containsKey('cured meat') ||
        widget.pathSystem.outfit['cured meat']! < 5) {
      widget.pathSystem.outfit['cured meat'] = 10;
    }

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
      WorldSystem.VILLAGE_POS[0],
      WorldSystem.VILLAGE_POS[1]
    ];
    widget.worldSystem.lastPosition = List.from(widget.worldSystem.position!);
    widget.worldSystem.updateMask();
    _validateWorldState();
    setState(() {});
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('位置已重置到村庄')));
  }
}
