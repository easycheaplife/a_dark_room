import 'dart:math';
import 'package:flutter/foundation.dart';
import 'game_state.dart';

class PathSystem extends ChangeNotifier {
  // 物品重量定义
  static const Map<String, double> WEIGHT = {
    'bone spear': 2,
    'iron sword': 3,
    'steel sword': 5,
    'rifle': 5,
    'bullets': 0.1,
    'energy cell': 0.2,
    'laser rifle': 5,
    'plasma rifle': 5,
    'bolas': 0.5,
  };

  // 默认背包容量
  static const int DEFAULT_BAG_SPACE = 10;

  // 背包内物品
  Map<String, int> outfit = {};

  // 获取物品重量
  double getWeight(String item) {
    return WEIGHT[item] ?? 1.0;
  }

  // 获取背包容量
  int getCapacity() {
    var gameState = GameState();
    if (gameState.resources['cargo drone'] != null &&
        gameState.resources['cargo drone']! > 0) {
      return DEFAULT_BAG_SPACE + 100;
    } else if (gameState.resources['convoy'] != null &&
        gameState.resources['convoy']! > 0) {
      return DEFAULT_BAG_SPACE + 60;
    } else if (gameState.resources['wagon'] != null &&
        gameState.resources['wagon']! > 0) {
      return DEFAULT_BAG_SPACE + 30;
    } else if (gameState.resources['rucksack'] != null &&
        gameState.resources['rucksack']! > 0) {
      return DEFAULT_BAG_SPACE + 10;
    }
    return DEFAULT_BAG_SPACE;
  }

  // 获取剩余空间
  double getFreeSpace() {
    double usedSpace = 0;
    outfit.forEach((item, count) {
      usedSpace += count * getWeight(item);
    });
    return getCapacity() - usedSpace;
  }

  // 增加物品到背包
  bool addToOutfit(String item, int count) {
    if (count <= 0) return false;

    // 检查是否有足够的物品
    var gameState = GameState();
    int available = gameState.resources[item] ?? 0;
    if (available < count) {
      count = available;
      if (count <= 0) return false;
    }

    // 检查是否有足够的空间
    double itemWeight = getWeight(item);
    if (getFreeSpace() < itemWeight * count) {
      // 计算最多能携带多少
      int maxPossible = (getFreeSpace() / itemWeight).floor();
      if (maxPossible <= 0) return false;
      count = maxPossible;
    }

    // 更新背包
    outfit[item] = (outfit[item] ?? 0) + count;

    // 从仓库中移除
    gameState.useResource(item, count);

    notifyListeners();
    return true;
  }

  // 从背包中移除物品
  bool removeFromOutfit(String item, int count) {
    if (count <= 0 || outfit[item] == null || outfit[item]! <= 0) return false;

    // 限制移除数量
    if (count > outfit[item]!) {
      count = outfit[item]!;
    }

    // 更新背包
    outfit[item] = outfit[item]! - count;
    if (outfit[item] == 0) {
      outfit.remove(item);
    }

    // 返回到仓库
    var gameState = GameState();
    gameState.addResource(item, count);

    notifyListeners();
    return true;
  }

  // 检查是否可以出发
  bool canEmbark() {
    return outfit.containsKey('cured meat') && (outfit['cured meat'] ?? 0) > 0;
  }

  // 出发前的准备
  void embark(GameState gameState) {
    // 清空背包中的物品（已经在 gameState 中扣除了）
    outfit.clear();

    // 切换到世界地图
    gameState.currentLocation = 'world';

    notifyListeners();
  }

  // 从JSON加载
  void fromJson(Map<String, dynamic> json) {
    outfit = Map<String, int>.from(json['outfit'] ?? {});
  }

  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'outfit': outfit,
    };
  }
}
