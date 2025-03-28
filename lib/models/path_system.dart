import 'package:flutter/foundation.dart';
import '../config/game_settings.dart';

/// 探索路径系统 - 管理背包装备和路径相关逻辑
class PathSystem extends ChangeNotifier {
  // 背包当前物品
  Map<String, int> outfit = {};

  // 默认背包空间
  static const int DEFAULT_BAG_SPACE = 10;

  // 物品重量配置
  static const Map<String, double> Weight = {
    // 基础资源
    'cured meat': 1.0,
    'jerky': 0.5,
    'meat': 1.5,
    'water': 1.5,
    'fur': 1.0,
    'wood': 2.0,
    'cloth': 0.5,
    'scales': 0.3,
    'teeth': 0.2,
    'leather': 1.0,
    'iron': 2.0,
    'steel': 2.5,
    'coal': 1.0,
    'sulphur': 0.5,
    'medicine': 0.3,

    // 武器
    'bone spear': 2.0,
    'iron sword': 3.0,
    'steel sword': 3.5,
    'rifle': 5.0,
    'laser rifle': 5.0,
    'bolas': 1.0,
    'grenades': 1.0,
    'bayonet': 2.0,
    'bullets': 0.4,
    'energy cell': 0.2,

    // 装备
    'torch': 1.0,
    'compass': 0.5,
    'l armour': 3.0,
    'i armour': 5.0,
    's armour': 6.0,

    // 工具
    'axe': 2.0,
    'steel axe': 3.0,
    'chainsaw': 4.0,
    'map': 0.3,
    'charm': 0.1,

    // 背包升级
    'rucksack': 1.0,
    'wagon': 2.0,
    'convoy': 3.0,
  };

  // 可装备的物品类型
  static const List<String> EQUIPABLE_ITEMS = [
    'cured meat',
    'jerky',
    'water',
    'medicine',
    'bullets',
    'energy cell',
    'torch',
    'rifle',
    'laser rifle',
    'steel sword',
    'iron sword',
    'bone spear',
    'bolas',
    'l armour',
    'i armour',
    's armour',
    'compass',
    'map',
    'charm'
  ];

  /// 检查物品是否可装备
  bool isEquipable(String itemId) {
    return EQUIPABLE_ITEMS.contains(itemId) ||
        // 这里可以添加更多的判断逻辑
        (itemId.contains('armour') || itemId.contains('weapon'));
  }

  /// 获取物品重量
  double getItemWeight(String itemId) {
    return Weight[itemId] ?? 1.0; // 默认每单位物品重量为1.0
  }

  /// 计算当前装备的总重量
  double getTotalWeight() {
    double total = 0;
    outfit.forEach((itemId, quantity) {
      total += (getItemWeight(itemId) * quantity);
    });
    return total;
  }

  /// 获取背包容量
  int getCapacity() {
    int capacity = DEFAULT_BAG_SPACE;

    // 开发者模式下增加背包容量
    if (kDebugMode || GameSettings.devMode) {
      // 开发模式下默认100单位容量
      capacity = 100;

      // 如果开启了无限资源选项，提供极大的背包空间
      if (GameSettings.devOptions['UNLIMITED_RESOURCES'] == true) {
        capacity = 999;
      }
    } else {
      // 正常游戏模式下的背包升级增加容量
      if (outfit.containsKey('rucksack')) {
        capacity += (outfit['rucksack']! * 10);
      }
      if (outfit.containsKey('wagon')) {
        capacity += (outfit['wagon']! * 20);
      }
      if (outfit.containsKey('convoy')) {
        capacity += (outfit['convoy']! * 30);
      }
    }

    return capacity;
  }

  /// 获取剩余背包空间
  int getFreeSpace() {
    int capacity = getCapacity();
    double totalWeight = getTotalWeight();

    // 将double转为int，并确保不会返回负数
    int freeSpace = (capacity - totalWeight).floor();
    if (freeSpace < 0) {
      if (kDebugMode) {
        print('警告: 背包超载! 容量: $capacity, 总重量: $totalWeight');
      }
      return 0;
    }
    return freeSpace;
  }

  /// 增加物品到背包
  bool increaseSupply(String itemId) {
    // 检查物品是否可以装备
    if (!isEquipable(itemId)) {
      if (kDebugMode) {
        print('$itemId 不能被装备');
      }
      return false;
    }

    // 检查背包空间
    double itemWeight = getItemWeight(itemId);
    if (getFreeSpace() < itemWeight) {
      if (kDebugMode) {
        print('背包空间不足，无法添加 $itemId');
      }
      return false;
    }

    // 增加物品
    if (outfit.containsKey(itemId)) {
      outfit[itemId] = outfit[itemId]! + 1;
    } else {
      outfit[itemId] = 1;
    }

    notifyListeners();
    if (kDebugMode) {
      print('添加了 $itemId 到背包');
    }
    return true;
  }

  /// 从背包移除物品
  bool decreaseSupply(String itemId) {
    if (!outfit.containsKey(itemId) || outfit[itemId]! <= 0) {
      return false;
    }

    outfit[itemId] = outfit[itemId]! - 1;

    // 如果数量为0，从背包中移除该物品
    if (outfit[itemId] == 0) {
      outfit.remove(itemId);
    }

    notifyListeners();
    return true;
  }

  /// 清空背包
  void clearOutfit() {
    outfit.clear();
    notifyListeners();
  }

  // 检查是否可以出发
  bool canEmbark() {
    // 必须至少有熏肉才能出发
    return outfit.containsKey('cured meat') && (outfit['cured meat'] ?? 0) > 0;
  }

  // 出发前的准备
  void embark() {
    // 清空背包中的物品（已经在 gameState 中扣除了）
    outfit.clear();
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

  /// 消耗一个食物单位
  bool consumeFood() {
    // 首先尝试消耗熏肉(cured meat)
    if (outfit.containsKey('cured meat') && outfit['cured meat']! > 0) {
      outfit['cured meat'] = outfit['cured meat']! - 1;
      if (outfit['cured meat'] == 0) {
        outfit.remove('cured meat');
      }
      if (kDebugMode) {
        print('消耗了一个熏肉，剩余: ${outfit['cured meat'] ?? 0}');
      }
      notifyListeners();
      return true;
    }

    // 如果没有熏肉，尝试消耗肉干(jerky)
    if (outfit.containsKey('jerky') && outfit['jerky']! > 0) {
      outfit['jerky'] = outfit['jerky']! - 1;
      if (outfit['jerky'] == 0) {
        outfit.remove('jerky');
      }
      if (kDebugMode) {
        print('消耗了一个肉干，剩余: ${outfit['jerky'] ?? 0}');
      }
      notifyListeners();
      return true;
    }

    // 没有食物可消耗
    return false;
  }

  /// 检查是否有食物
  bool hasFood() {
    return (outfit.containsKey('cured meat') && outfit['cured meat']! > 0) ||
        (outfit.containsKey('jerky') && outfit['jerky']! > 0);
  }

  /// 检查是否可以添加物品到背包
  bool canAddSupply(String type) {
    // 在调试模式下，允许无限添加物资
    if (kDebugMode || GameSettings.devMode) {
      return true;
    }

    // 开发者模式下无限资源
    if (GameSettings.devOptions['UNLIMITED_RESOURCES'] == true) {
      return true;
    }

    // 在正常游戏模式中，检查背包空间
    double itemWeight = getItemWeight(type);
    return getFreeSpace() >= itemWeight;
  }
}
