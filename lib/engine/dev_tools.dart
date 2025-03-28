import 'package:flutter/foundation.dart';
import '../models/game_state.dart';
import '../config/game_settings.dart';
import '../models/world_system.dart';

/// 开发者工具类，提供各种调试和测试功能
class DevTools {
  /// 初始化开发者模式
  static void init(GameState gameState) {
    if (!kDebugMode || !GameSettings.DEV_MODE) return;

    if (GameSettings.DEV_OPTIONS['UNLOCK_ALL'] == true) {
      unlockAllFeatures(gameState);
    }

    if (GameSettings.DEV_OPTIONS['UNLIMITED_RESOURCES'] == true) {
      addUnlimitedResources(gameState);
    }

    if (GameSettings.DEV_OPTIONS['QUICK_TEST_PATH'] == true) {
      setupPathTesting(gameState);
    }

    if (kDebugMode) {
      print('开发者模式已启用: ${GameSettings.DEV_OPTIONS}');
    }
  }

  /// 快速测试路径系统
  static void setupPathTesting(GameState gameState) {
    // 确保解锁相关功能
    gameState.outsideUnlocked = true;
    gameState.storeOpened = true;

    // 添加测试所需资源
    gameState.addResource('cured meat', 50);
    gameState.addResource('water', 50);
    gameState.addResource('wood', 100);
    gameState.addResource('fur', 50);
    gameState.addResource('leather', 20);
    gameState.addResource('meat', 30);

    // 添加武器和装备
    gameState.addResource('bone spear', 2);
    gameState.addResource('iron sword', 1);
    gameState.addResource('steel sword', 1);
    gameState.addResource('rifle', 1);
    gameState.addResource('bullets', 20);
    gameState.addResource('medicine', 10);

    // 添加背包升级
    gameState.addResource('rucksack', 1);

    if (kDebugMode) {
      print('路径系统测试设置已完成');
    }
  }

  /// 解锁所有功能
  static void unlockAllFeatures(GameState gameState) {
    // 解锁基本功能
    gameState.outsideUnlocked = true;
    gameState.storeOpened = true;
    gameState.craftingUnlocked = true;

    // 初始化世界系统
    gameState.worldSystem.init();

    // 添加大量基础资源
    addUnlimitedResources(gameState);

    // 添加金钱
    gameState.addResource('money', 10000);

    // 解锁建筑
    const Map<String, int> buildings = {
      'hut': 5,
      'cart': 3,
      'lodge': 2,
      'trading post': 1,
      'tannery': 1,
      'smokehouse': 1,
      'workshop': 1,
      'steelworks': 1,
      'armoury': 1,
      'trap': 5,
      'curing rack': 3,
      'barn': 3,
      'well': 1,
      'mine': 3,
      'coal mine': 3,
      'iron mine': 3,
      'sulphur mine': 3,
      'cement kiln': 1,
      'torch': 10,
    };

    buildings.forEach((building, count) {
      gameState.room['buildings'][building] = count;
      // 设置建筑等级为最高
      gameState.buildingLevels[building] = 3;
    });

    // 解锁所有村民类型
    const Map<String, int> villagers = {
      'gatherer': 5,
      'hunter': 5,
      'trapper': 5,
      'tanner': 3,
      'miner': 5,
      'coal miner': 5,
      'iron miner': 5,
      'sulphur miner': 5,
      'steelworker': 3,
      'armourer': 3,
      'smith': 3,
      'builder': 3,
      'charcutier': 3,
    };

    // 确保worker字典已初始化
    if (gameState.population['workers'] is! Map) {
      gameState.population['workers'] = {};
    }

    villagers.forEach((type, count) {
      gameState.population['workers'][type] = count;
    });

    // 设置总人口
    int totalPopulation = villagers.values.fold(0, (sum, count) => sum + count);
    gameState.population['total'] = totalPopulation;
    gameState.population['max'] = totalPopulation + 10;
    gameState.population['happiness'] = 100;

    // 解锁所有武器和工具
    gameState.addResource('bone spear', 5);
    gameState.addResource('iron sword', 3);
    gameState.addResource('steel sword', 3);
    gameState.addResource('rifle', 3);
    gameState.addResource('laser rifle', 1);
    gameState.addResource('bolas', 5);
    gameState.addResource('axe', 5);
    gameState.addResource('steel axe', 3);
    gameState.addResource('chainsaw', 1);
    gameState.addResource('rucksack', 3);
    gameState.addResource('wagon', 1);
    gameState.addResource('convoy', 1);
    gameState.addResource('l armour', 3);
    gameState.addResource('i armour', 3);
    gameState.addResource('s armour', 3);

    if (kDebugMode) {
      print('所有功能已解锁');
    }
  }

  /// 添加大量资源
  static void addUnlimitedResources(GameState gameState) {
    const Map<String, int> resources = {
      'wood': 1000,
      'fur': 500,
      'meat': 500,
      'scales': 200,
      'teeth': 200,
      'leather': 500,
      'iron': 500,
      'coal': 500,
      'steel': 300,
      'cured meat': 300,
      'cloth': 200,
      'bullets': 100,
      'energy cell': 50,
      'alien alloy': 20,
      'medicine': 50,
      'water': 500,
    };

    resources.forEach((resource, amount) {
      gameState.addResource(resource, amount);
    });

    if (kDebugMode) {
      print('已添加大量资源');
    }
  }

  /// 快速跳转到测试路径系统
  static void quickJumpToPath(GameState gameState) {
    // 先解锁所有功能确保路径系统正常
    unlockAllFeatures(gameState);

    // 再设置路径测试专用资源
    setupPathTesting(gameState);

    // 确保物品在背包中为空，准备装配
    gameState.pathSystem.clearOutfit();

    // 跳转到路径
    gameState.currentLocation = 'path';

    if (kDebugMode) {
      print('已跳转到路径装备界面');
      print('路径系统状态: 已初始化');
      print('当前装备: ${gameState.pathSystem.outfit}');
    }
  }

  /// 快速跳转到世界地图
  static void quickJumpToWorld(GameState gameState) {
    // 先解锁所有功能确保路径和世界系统正常
    unlockAllFeatures(gameState);

    // 再设置路径测试专用资源
    setupPathTesting(gameState);

    // 确保有足够物品在背包中
    gameState.pathSystem.clearOutfit();
    gameState.pathSystem.increaseSupply('cured meat');
    gameState.pathSystem.increaseSupply('cured meat');
    gameState.pathSystem.increaseSupply('cured meat');
    gameState.pathSystem.increaseSupply('cured meat');
    gameState.pathSystem.increaseSupply('cured meat');

    gameState.pathSystem.increaseSupply('bullets');
    gameState.pathSystem.increaseSupply('bullets');
    gameState.pathSystem.increaseSupply('medicine');
    gameState.pathSystem.increaseSupply('rifle');
    gameState.pathSystem.increaseSupply('steel sword');

    // 重置状态
    gameState.worldSystem.resetWorld();

    // 确保水资源充足
    gameState.worldSystem.water = WorldSystem.baseWater;
    gameState.worldSystem.moves = 0;
    gameState.worldSystem.totalMoveCount = 0;

    // 确保位置正确设置在村庄位置
    gameState.worldSystem.position = [
      WorldSystem.villagePos[0],
      WorldSystem.villagePos[1]
    ];
    gameState.worldSystem.lastPosition =
        List.from(gameState.worldSystem.position);

    // 更新可见范围
    gameState.worldSystem.updateMask();

    // 跳转到世界地图
    gameState.currentLocation = 'world';

    if (kDebugMode) {
      print('已跳转到世界地图');
      print('世界系统状态: 已初始化');
      print('玩家位置: ${gameState.worldSystem.position}');
      print('水量: ${gameState.worldSystem.water}');
      print('背包内容: ${gameState.pathSystem.outfit}');
    }
  }
}
