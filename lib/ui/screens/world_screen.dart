import 'package:flutter/material.dart';
import '../../models/game_state.dart';
import '../../models/path_system.dart';
import '../../models/world_system.dart';

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

  @override
  void initState() {
    super.initState();
    // 确保世界系统已初始化
    if (widget.worldSystem.map.isEmpty) {
      widget.worldSystem.init();
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

            // 返回村庄按钮
            TextButton.icon(
              icon: const Icon(Icons.home, color: Colors.white),
              label: const Text('村庄', style: TextStyle(color: Colors.white)),
              onPressed: () {
                widget.gameState.currentLocation = 'room';
                setState(() {});
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
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // 计算可视区域大小
    int viewRadius = 10; // 可视区半径
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
    return InteractiveViewer(
      constrained: false,
      boundaryMargin: const EdgeInsets.all(100),
      minScale: 0.5,
      maxScale: 2.0,
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

                return Positioned(
                  left: x * tileSize,
                  top: y * tileSize,
                  child: Container(
                    width: tileSize,
                    height: tileSize,
                    color: tileColors[tile] ?? Colors.grey,
                    child: (mapX == playerX && mapY == playerY)
                        ? const Icon(
                            Icons.person,
                            size: 16,
                            color: Colors.white,
                          )
                        : null,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 北按钮
                _buildDirectionButton(
                  icon: Icons.arrow_upward,
                  direction: WorldSystem.NORTH,
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 西按钮
                _buildDirectionButton(
                  icon: Icons.arrow_back,
                  direction: WorldSystem.WEST,
                ),
                const SizedBox(width: 60), // 中间的间距
                // 东按钮
                _buildDirectionButton(
                  icon: Icons.arrow_forward,
                  direction: WorldSystem.EAST,
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 南按钮
                _buildDirectionButton(
                  icon: Icons.arrow_downward,
                  direction: WorldSystem.SOUTH,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 构建方向按钮
  Widget _buildDirectionButton({
    required IconData icon,
    required List<int> direction,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueGrey.shade700,
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(16),
      ),
      onPressed: () {
        // 移动
        bool moved = widget.worldSystem.move(
          direction,
          widget.gameState,
          widget.pathSystem,
        );

        if (moved) {
          // 更新UI
          setState(() {});
        }
      },
      child: Icon(icon, color: Colors.white),
    );
  }
}
