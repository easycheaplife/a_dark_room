import 'package:flutter/material.dart';
import '../../engine/game_engine.dart';

/// 户外屏幕 - 村庄和探索
class OutsideScreen extends StatefulWidget {
  const OutsideScreen({Key? key}) : super(key: key);

  @override
  State<OutsideScreen> createState() => _OutsideScreenState();
}

class _OutsideScreenState extends State<OutsideScreen> {
  final GameEngine _engine = GameEngine();
  List<String> _logs = ['外面是一片森林。']; // 游戏日志
  Map<String, int> _resources = {}; // 资源

  @override
  void initState() {
    super.initState();
    _engine.stateChangeNotifier.addListener(_updateState);
    _updateState();
  }

  @override
  void dispose() {
    _engine.stateChangeNotifier.removeListener(_updateState);
    super.dispose();
  }

  // 更新状态
  void _updateState() {
    if (_engine.gameState != null) {
      setState(() {
        _resources = Map<String, int>.from(_engine.gameState!.resources);
      });
    }
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

  // 探索森林
  void _exploreForest() {
    // 随机获取资源
    double chance = (DateTime.now().millisecondsSinceEpoch % 100) / 100;

    if (chance < 0.5) {
      _engine.updateGameState((state) {
        state.addResource('wood', 2);
      });
      _addLog('找到了一些木头。');
    } else if (chance < 0.7) {
      _engine.updateGameState((state) {
        state.addResource('fur', 1);
      });
      _addLog('捕获了一只小动物。');
    } else if (chance < 0.8) {
      _engine.updateGameState((state) {
        state.addResource('meat', 1);
      });
      _addLog('获得了一些肉。');
    } else {
      _addLog('什么也没找到。');
    }

    _updateState();
  }

  // 返回房间
  void _returnToRoom() {
    _engine.updateGameState((state) {
      state.currentLocation = 'room';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        _buildOutsideView(),
        _buildLogView(),
        _buildActionButtons(),
      ],
    );
  }

  // 构建头部信息
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(10),
      color: Colors.black,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '外部世界',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: Icon(Icons.home, color: Colors.white),
                onPressed: _returnToRoom,
                tooltip: '返回房间',
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildResourceBar(),
        ],
      ),
    );
  }

  // 构建资源条
  Widget _buildResourceBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        _buildResourceIndicator('木头', _resources['wood'] ?? 0),
        if (_resources['fur'] != null && _resources['fur']! > 0)
          _buildResourceIndicator('毛皮', _resources['fur'] ?? 0),
        if (_resources['meat'] != null && _resources['meat']! > 0)
          _buildResourceIndicator('肉', _resources['meat'] ?? 0),
      ],
    );
  }

  // 构建单个资源指示器
  Widget _buildResourceIndicator(String name, int value) {
    return Padding(
      padding: const EdgeInsets.only(right: 15),
      child: Text(
        '$name: $value',
        style: TextStyle(
          color: Colors.grey.shade300,
          fontSize: 14,
        ),
      ),
    );
  }

  // 构建外部视图
  Widget _buildOutsideView() {
    return Expanded(
      flex: 2,
      child: Container(
        width: double.infinity,
        color: Colors.black,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.forest,
                  color: Colors.green,
                  size: 60,
                ),
                const SizedBox(width: 20),
                Icon(
                  Icons.home,
                  color: Colors.brown,
                  size: 60,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              '森林环绕着一个小村庄。',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // 构建日志视图
  Widget _buildLogView() {
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
      padding: const EdgeInsets.all(10),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _buildActionButton('探索森林', true, _exploreForest),
          _buildActionButton('返回房间', true, _returnToRoom),
        ],
      ),
    );
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
}
