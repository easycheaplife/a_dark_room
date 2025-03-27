import 'package:flutter/material.dart';
import '../../models/game_state.dart';
import '../../models/path_system.dart';
import '../../models/world_system.dart';

class OutfitScreen extends StatefulWidget {
  final GameState gameState;
  final PathSystem pathSystem;
  final WorldSystem worldSystem;
  final Function onEmbark;

  const OutfitScreen({
    Key? key,
    required this.gameState,
    required this.pathSystem,
    required this.worldSystem,
    required this.onEmbark,
  }) : super(key: key);

  @override
  State<OutfitScreen> createState() => _OutfitScreenState();
}

class _OutfitScreenState extends State<OutfitScreen> {
  // 可携带物品的列表
  final List<String> carryableItems = [
    'cured meat',
    'bullets',
    'energy cell',
    'medicine',
    'bolas',
    'charm',
    'bone spear',
    'iron sword',
    'steel sword',
    'bayonet',
    'rifle',
    'laser rifle',
    'grenade',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('准备出发'),
        backgroundColor: Colors.brown.shade800,
      ),
      backgroundColor: Colors.brown.shade200,
      body: Column(
        children: [
          // 背包容量显示
          _buildBagSpaceIndicator(),

          // 物品列表
          Expanded(
            child: _buildItemList(),
          ),

          // 底部按钮
          _buildBottomButtons(),
        ],
      ),
    );
  }

  // 构建背包容量指示器
  Widget _buildBagSpaceIndicator() {
    double usedSpace =
        widget.pathSystem.getCapacity() - widget.pathSystem.getFreeSpace();
    double capacityPercentage = usedSpace / widget.pathSystem.getCapacity();

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.backpack, color: Colors.brown),
              const SizedBox(width: 8),
              Text(
                '背包空间: ${widget.pathSystem.getFreeSpace().toStringAsFixed(1)}/${widget.pathSystem.getCapacity()}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: capacityPercentage,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(
              capacityPercentage > 0.8 ? Colors.red : Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  // 构建物品列表
  Widget _buildItemList() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: carryableItems.length,
      itemBuilder: (context, index) {
        String item = carryableItems[index];
        int available = widget.gameState.resources[item] ?? 0;
        int equipped = widget.pathSystem.outfit[item] ?? 0;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: ListTile(
            title: Text(_formatItemName(item)),
            subtitle: Row(
              children: [
                Text('重量: ${widget.pathSystem.getWeight(item)}'),
                const SizedBox(width: 16),
                Text('可用: ${available}'),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 减少按钮
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  color: equipped > 0 ? Colors.red : Colors.grey,
                  onPressed: equipped > 0
                      ? () {
                          widget.pathSystem.removeFromOutfit(item, 1);
                          setState(() {});
                        }
                      : null,
                ),

                // 数量显示
                Container(
                  width: 40,
                  alignment: Alignment.center,
                  child: Text(
                    equipped.toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),

                // 增加按钮
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  color: (available > equipped &&
                          widget.pathSystem.getFreeSpace() >=
                              widget.pathSystem.getWeight(item))
                      ? Colors.green
                      : Colors.grey,
                  onPressed: (available > equipped &&
                          widget.pathSystem.getFreeSpace() >=
                              widget.pathSystem.getWeight(item))
                      ? () {
                          widget.pathSystem.addToOutfit(item, 1);
                          setState(() {});
                        }
                      : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 构建底部按钮
  Widget _buildBottomButtons() {
    bool canEmbark = widget.pathSystem.canEmbark();

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 返回按钮
          ElevatedButton.icon(
            icon: const Icon(Icons.arrow_back),
            label: const Text('返回'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),

          // 出发按钮
          ElevatedButton.icon(
            icon: const Icon(Icons.directions_walk),
            label: const Text('出发'),
            style: ElevatedButton.styleFrom(
              backgroundColor: canEmbark ? Colors.green : Colors.grey,
              foregroundColor: Colors.white,
            ),
            onPressed: canEmbark
                ? () {
                    widget.pathSystem.embark(widget.gameState);
                    widget.onEmbark();
                  }
                : null,
          ),
        ],
      ),
    );
  }

  // 格式化物品名称显示
  String _formatItemName(String name) {
    // 首字母大写并替换下划线为空格
    return name.split(' ').map((word) {
      return word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '';
    }).join(' ');
  }
}
