import 'package:flutter/foundation.dart';
import '../models/game_state.dart';
import '../config/game_settings.dart';
import '../models/world_system.dart';
import '../models/game_event.dart' as game_event;

/// 开发者工具类，提供各种调试和测试功能
class DevTools {
  /// 初始化开发者模式
  static void init(GameState gameState) {
    if (!kDebugMode || !GameSettings.devMode) return;

    if (GameSettings.devOptions['UNLOCK_ALL'] == true) {
      unlockAllFeatures(gameState);
    }

    if (GameSettings.devOptions['UNLIMITED_RESOURCES'] == true) {
      addUnlimitedResources(gameState);
    }

    if (GameSettings.devOptions['QUICK_TEST_PATH'] == true) {
      setupPathTesting(gameState);
    }

    if (kDebugMode) {
      print('开发者模式已启用: ${GameSettings.devOptions}');
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

  /// 触发故事系统事件（用于测试）- 分成了两个独立的测试函数
  static void triggerStoryEvent(GameState gameState) {
    if (kDebugMode) {
      print('请选择要测试的故事事件类型...');
      print('- 陌生人事件请使用: triggerStrangerEvent(gameState)');
      print('- 进度事件请使用: triggerProgressEvent(gameState)');

      // 默认触发陌生人事件
      triggerStrangerEvent(gameState);
    }
  }

  /// 专门测试陌生人事件系列
  static void triggerStrangerEvent(GameState gameState) {
    if (kDebugMode) {
      print('触发陌生人事件系列测试...');

      // 确保火堆已点燃
      if (gameState.room is! Map<String, dynamic>) {
        gameState.room = <String, dynamic>{};
      }
      gameState.room['fire'] = 1;
      gameState.room['temperature'] = 'warm';

      // 设置游戏时间（确保满足条件）
      gameState.gameStartTime =
          DateTime.now().subtract(const Duration(minutes: 15));
      gameState.gamePlayTime = const Duration(minutes: 15);

      print('游戏时间: ${gameState.gamePlayTime.inMinutes}分钟');
      print('火堆状态: ${gameState.room['fire']}');

      // 根据陌生人标记状态决定操作
      bool strangerArrived =
          gameState.storySystem.storyFlags['strangerArrived'] ?? false;

      if (strangerArrived) {
        // 如果陌生人已到达，重置标记以重新测试
        gameState.storySystem.storyFlags['strangerArrived'] = false;
        // 同时重置相关的后续事件标记
        gameState.storySystem.storyFlags['buildingHut'] = false;
        gameState.storySystem.storyFlags['villageStarted'] = false;
        print('已重置陌生人事件标记和相关后续事件');
        gameState.notifyListeners(); // 确保UI更新
        return;
      }

      // 尝试触发陌生人事件
      print('正在触发陌生人事件...');
      // 使用公共方法checkStoryProgress代替直接调用私有方法
      gameState.storySystem.checkStoryProgress();

      // 检查事件是否已触发
      if (gameState.storySystem.currentEvent != null) {
        print('成功触发陌生人事件!');
        final event = gameState.storySystem.currentEvent!;

        // 安全地获取事件标题和描述
        String title = '未知事件';
        String description = '无描述';

        final titleValue = event['title'];
        final descValue = event['description'];

        if (titleValue != null) {
          title = titleValue.toString();
        }
        if (descValue != null) {
          description = descValue.toString();
        }

        print('标题: $title');
        print('内容: $description');
      } else {
        print('触发陌生人事件失败，请检查故事系统');
      }

      // 确保更新UI
      gameState.notifyListeners();
    }
  }

  /// 测试基于进度的故事事件（建筑数量、资源数量等）
  static void triggerProgressEvent(GameState gameState) {
    if (kDebugMode) {
      print('测试基于进度的故事事件...');

      // 获取当前状态
      int hutCount = gameState.getBuildingCount('hut') ?? 0;
      int trapCount = gameState.getBuildingCount('trap') ?? 0;
      int tradingPostCount = gameState.getBuildingCount('trading post') ?? 0;
      int storeOpened = gameState.storeOpened ? 1 : 0;

      // 显示当前游戏状态
      print('当前游戏状态:');
      print('- 小屋数量: $hutCount');
      print('- 陷阱数量: $trapCount');
      print('- 交易所: $tradingPostCount');
      print('- 商店已开放: $storeOpened');
      print('- 人口总数: ${gameState.population['total'] ?? 0}');

      // 创建必要的进度条件
      bool canTriggerHutEvent =
          gameState.storySystem.storyFlags['buildingHut'] != true &&
              hutCount > 0;
      bool canTriggerVillageEvent =
          gameState.storySystem.storyFlags['villageStarted'] != true &&
              hutCount >= 3;
      bool canTriggerTradingEvent =
          gameState.storySystem.storyFlags['tradingPostBuilt'] != true &&
              trapCount >= 5 &&
              hutCount >= 3;
      bool canTriggerMinersEvent =
          gameState.storySystem.storyFlags['minersArrived'] != true &&
              tradingPostCount > 0 &&
              (gameState.population['total'] ?? 0) >= 10;

      // 检查下一个可能触发的事件并手动设置条件
      if (canTriggerHutEvent) {
        print('条件满足: 可以触发小屋建造事件');
        // 模拟小屋建造事件的条件，然后通过公共方法触发
        gameState.addResource('wood', 100);
        if (gameState.room['buildings'] is! Map<String, dynamic>) {
          gameState.room['buildings'] = <String, dynamic>{};
        }
        gameState.room['buildings']['hut'] = 1;
        gameState.storySystem.checkStoryProgress();
      } else if (canTriggerVillageEvent) {
        print('条件满足: 可以触发村庄建设事件');
        // 模拟村庄建设事件的条件
        if (gameState.room['buildings'] is! Map<String, dynamic>) {
          gameState.room['buildings'] = <String, dynamic>{};
        }
        gameState.room['buildings']['hut'] = 3;
        gameState.storySystem.checkStoryProgress();
      } else if (canTriggerTradingEvent) {
        print('条件满足: 可以触发交易所建设事件');
        // 模拟交易所建设事件的条件
        if (gameState.room['buildings'] is! Map<String, dynamic>) {
          gameState.room['buildings'] = <String, dynamic>{};
        }
        gameState.room['buildings']['trap'] = 5;
        gameState.room['buildings']['hut'] = 3;
        gameState.storySystem.checkStoryProgress();
      } else if (canTriggerMinersEvent) {
        print('条件满足: 可以触发矿工到达事件');
        // 模拟矿工到达事件的条件
        if (gameState.room['buildings'] is! Map<String, dynamic>) {
          gameState.room['buildings'] = <String, dynamic>{};
        }
        gameState.room['buildings']['trading post'] = 1;
        if (gameState.population is! Map<String, dynamic>) {
          gameState.population = <String, dynamic>{};
        }
        gameState.population['total'] = 10;
        gameState.storySystem.checkStoryProgress();
      } else {
        print('无法触发下一个进度事件，条件不满足');
        print('提示: 尝试增加小屋、陷阱或人口数量');

        // 添加一些资源以帮助玩家测试
        gameState.addResource('wood', 200);
        gameState.addResource('fur', 100);
        print('已添加一些资源以帮助测试: 木头x200, 皮毛x100');
      }

      // 检查事件是否已触发
      if (gameState.storySystem.currentEvent != null) {
        print('成功触发事件!');
        final event = gameState.storySystem.currentEvent!;

        // 安全地获取事件标题
        String title = '未知事件';
        final titleValue = event['title'];
        if (titleValue != null) {
          title = titleValue.toString();
        }

        print('标题: $title');
      } else {
        print('没有触发任何事件');
      }

      // 确保UI更新
      gameState.notifyListeners();
    }
  }
}
