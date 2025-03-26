import 'package:flutter/material.dart';
import '../../engine/game_engine.dart';
import '../../models/game_state.dart';

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

  @override
  void initState() {
    super.initState();
    widget.gameState.addListener(_updateState);
    _updateState();
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
