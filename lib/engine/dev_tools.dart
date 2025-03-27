import 'package:flutter/foundation.dart';
import '../models/game_state.dart';
import '../config/game_settings.dart';

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
    gameState.outsideUnlocked = true;
    gameState.storeOpened = true;
    gameState.craftingUnlocked = true;

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
    };

    buildings.forEach((building, count) {
      gameState.room['buildings'][building] = count;
    });

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
    setupPathTesting(gameState);
    gameState.currentLocation = 'path';
    gameState.notifyListeners();

    if (kDebugMode) {
      print('已跳转到路径装备界面');
    }
  }

  /// 快速跳转到世界地图
  static void quickJumpToWorld(GameState gameState) {
    setupPathTesting(gameState);

    // 预填充一些背包物品
    gameState.pathSystem.outfit['cured meat'] = 10;
    gameState.pathSystem.outfit['bullets'] = 5;
    gameState.pathSystem.outfit['medicine'] = 3;

    // 初始化世界地图
    if (gameState.worldSystem.map.isEmpty) {
      gameState.worldSystem.init();
    }

    // 跳转到世界
    gameState.currentLocation = 'world';
    gameState.notifyListeners();

    if (kDebugMode) {
      print('已跳转到世界地图');
    }
  }
}
