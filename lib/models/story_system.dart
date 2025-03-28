import 'dart:math';
import 'game_state.dart';
import '../config/game_settings.dart';
import 'package:flutter/foundation.dart';

/// 故事系统，管理游戏中的核心故事事件
class StorySystem {
  final GameState gameState;
  final Random _random = Random();

  // 用于存储当前事件
  Map<String, dynamic>? _currentEvent;

  // 故事标记，用于跟踪进度
  Map<String, bool> storyFlags = {
    'strangerArrived': false, // 陌生人到来事件已触发
    'buildingHut': false, // 建造小屋事件已触发
    'villageStarted': false, // 村庄开始建设
    'strangerLeft': false, // 陌生人离开事件已触发
    'discoveredOutside': false, // 探索外部世界已触发
    'tradingPostBuilt': false, // 建造交易所
    'minersArrived': false, // 矿工到来
    'steelworksBuilt': false, // 钢铁工坊建成
    'expeditionReady': false, // 远征准备就绪
    'foundShip': false, // 发现飞船
    'unlockedAlienTech': false, // 解锁外星科技
    'endgameReady': false, // 准备结束游戏
  };

  StorySystem(this.gameState);

  // 获取当前事件
  Map<String, dynamic>? get currentEvent => _currentEvent;

  // 设置当前事件
  set currentEvent(Map<String, dynamic>? event) {
    _currentEvent = event;
    gameState.notifyListeners();
  }

  // 序列化为JSON
  Map<String, dynamic> toJson() {
    return {
      'storyFlags': storyFlags,
    };
  }

  // 从JSON加载
  void fromJson(Map<String, dynamic> json) {
    if (json.containsKey('storyFlags')) {
      Map<String, dynamic> flags = json['storyFlags'];
      flags.forEach((key, value) {
        if (storyFlags.containsKey(key)) {
          storyFlags[key] = value;
        }
      });
    }
  }

  /// 检查并触发故事事件
  void checkStoryProgress() {
    // 确保故事标记非空
    final strangerArrived = storyFlags['strangerArrived'] ?? false;
    final buildingHut = storyFlags['buildingHut'] ?? false;
    final villageStarted = storyFlags['villageStarted'] ?? false;
    final tradingPostBuilt = storyFlags['tradingPostBuilt'] ?? false;
    final minersArrived = storyFlags['minersArrived'] ?? false;
    final steelworksBuilt = storyFlags['steelworksBuilt'] ?? false;
    final expeditionReady = storyFlags['expeditionReady'] ?? false;
    final foundShip = storyFlags['foundShip'] ?? false;
    final unlockedAlienTech = storyFlags['unlockedAlienTech'] ?? false;
    final endgameReady = storyFlags['endgameReady'] ?? false;

    if (!strangerArrived && _canTriggerStranger()) {
      _triggerStrangerArrival();
      return;
    }

    if (strangerArrived && !buildingHut && _hasRequiredResourcesForHut()) {
      _triggerBuildHut();
      return;
    }

    if (buildingHut && !villageStarted && _hasBuiltHut()) {
      _triggerVillageStarted();
      return;
    }

    // 新增的故事触发检查
    if (villageStarted && !tradingPostBuilt && _canBuildTradingPost()) {
      _triggerTradingPostBuilt();
      return;
    }

    if (tradingPostBuilt && !minersArrived && _hasEnoughResourcesForMiners()) {
      _triggerMinersArrival();
      return;
    }

    if (minersArrived && !steelworksBuilt && _canBuildSteelworks()) {
      _triggerSteelworksBuilt();
      return;
    }

    if (steelworksBuilt && !expeditionReady && _hasResourcesForExpedition()) {
      _triggerExpeditionReady();
      return;
    }

    // 末游条件检查
    if (expeditionReady && !foundShip && _hasDiscoveredShip()) {
      _triggerFoundShip();
      return;
    }

    if (foundShip && !unlockedAlienTech && _hasResourcesForAlienTech()) {
      _triggerUnlockAlienTech();
      return;
    }

    if (unlockedAlienTech && !endgameReady && _isReadyForEndgame()) {
      _triggerEndgameReady();
      return;
    }
  }

  // 陌生人到来的触发条件
  bool _canTriggerStranger() {
    // 在调试模式下，总是返回true以便测试
    if (kDebugMode && gameState.gamePlayTime.inSeconds >= 60) {
      print("调试模式下触发陌生人事件");
      return true;
    }

    // 普通游戏模式下的逻辑
    // 需要火堆点燃
    if (gameState.room['fire'] < 1) return false;

    // 需要游戏时间超过60秒
    if (gameState.gamePlayTime.inSeconds < 60) return false;

    // 有30%的概率触发
    return _random.nextDouble() < 0.3;
  }

  // 是否有足够资源建造小屋
  bool _hasRequiredResourcesForHut() {
    return (gameState.resources['wood'] ?? 0) >= 50;
  }

  // 是否已建造小屋
  bool _hasBuiltHut() {
    // 返回true如果小屋等级 > 0
    return (gameState.getBuildingCount('hut') ?? 0) > 0;
  }

  // 新增的触发条件检查方法
  bool _canBuildTradingPost() {
    // 检查是否有足够的资源和建筑数量来建造交易所
    return (gameState.resources['wood'] ?? 0) >= 100 &&
        (gameState.resources['fur'] ?? 0) >= 50 &&
        (gameState.getBuildingCount('hut') ?? 0) >= 3 &&
        (gameState.getBuildingCount('trap') ?? 0) >= 5;
  }

  bool _hasEnoughResourcesForMiners() {
    // 检查是否有足够的资源和建筑来吸引矿工
    return (gameState.resources['cured meat'] ?? 0) >= 100 &&
        (gameState.resources['leather'] ?? 0) >= 50 &&
        (gameState.getBuildingCount('trading post') ?? 0) >= 1 &&
        (gameState.population['total'] ?? 0) >= 10;
  }

  bool _canBuildSteelworks() {
    // 检查是否有足够的资源和建筑来建造钢铁工坊
    return (gameState.resources['iron'] ?? 0) >= 100 &&
        (gameState.resources['coal'] ?? 0) >= 50 &&
        (gameState.getBuildingCount('mine') ?? 0) >= 2 &&
        (gameState.population['total'] ?? 0) >= 15;
  }

  bool _hasResourcesForExpedition() {
    // 检查是否有足够的资源和装备来准备远征
    return (gameState.resources['cured meat'] ?? 0) >= 200 &&
        (gameState.resources['steel'] ?? 0) >= 100 &&
        (gameState.resources['medicine'] ?? 0) >= 50 &&
        (gameState.getBuildingCount('steelworks') ?? 0) >= 1 &&
        (gameState.population['total'] ?? 0) >= 20;
  }

  // 修复检查是否发现飞船的方法
  bool _hasDiscoveredShip() {
    // 检查是否已经探索足够的世界地图区域和移动次数
    return gameState.worldSystem.totalMoveCount >= 100 &&
        gameState.worldSystem.shipLocation != null;
  }

  bool _hasResourcesForAlienTech() {
    // 检查是否有足够的资源研究外星科技
    return (gameState.resources['alien alloy'] ?? 0) >= 50 &&
        (gameState.resources['circuits'] ?? 0) >= 50 &&
        (gameState.getBuildingCount('workshop') ?? 0) >= 3;
  }

  bool _isReadyForEndgame() {
    // 检查是否满足游戏结束条件
    return (gameState.resources['alien alloy'] ?? 0) >= 100 &&
        (gameState.resources['advanced tech'] ?? 0) >= 50 &&
        (gameState.getBuildingCount('spacecraft') ?? 0) >= 1;
  }

  // 触发陌生人到来事件
  void _triggerStrangerArrival() {
    if (kDebugMode) {
      print("正在创建陌生人事件...");
    }

    // 创建事件数据
    Map<String, dynamic> eventData = {
      'title':
          GameSettings.languageManager.get('stranger_title', category: 'story'),
      'description':
          GameSettings.languageManager.get('stranger_desc', category: 'story'),
      'choices': [
        {
          'text': GameSettings.languageManager.get('greet', category: 'story'),
          'callback': _greetStranger
        },
        {
          'text': GameSettings.languageManager.get('hide', category: 'story'),
          'callback': _hideFromStranger
        }
      ]
    };

    // 设置事件
    _currentEvent = eventData;

    // 游戏状态的currentEvent不要直接赋值，通过故事系统更新
    // gameState.currentEvent = eventData;

    // 更新标记
    storyFlags['strangerArrived'] = true;

    if (kDebugMode) {
      print("陌生人事件已创建并设置: ${eventData['title']}");
    }

    // 确保UI更新
    gameState.notifyListeners();
  }

  // 陌生人事件选择：问好
  void _greetStranger() {
    currentEvent = {
      'title': GameSettings.languageManager
          .get('kind_stranger_title', category: 'story'),
      'description': GameSettings.languageManager
          .get('kind_stranger_desc', category: 'story'),
      'choices': [
        {
          'text': GameSettings.languageManager.get('thank', category: 'story'),
          'callback': _acceptStrangerHelp
        }
      ]
    };
  }

  // 陌生人事件选择：躲起来
  void _hideFromStranger() {
    currentEvent = {
      'title': GameSettings.languageManager
          .get('cautious_stranger_title', category: 'story'),
      'description': GameSettings.languageManager
          .get('cautious_stranger_desc', category: 'story'),
      'choices': [
        {
          'text': GameSettings.languageManager.get('accept', category: 'story'),
          'callback': _acceptStrangerHelp
        }
      ]
    };
  }

  // 接受陌生人帮助
  void _acceptStrangerHelp() {
    // 解锁建造小屋的功能
    gameState.craftingUnlocked = true;
    currentEvent = null;
  }

  // 触发建造小屋事件
  void _triggerBuildHut() {
    currentEvent = {
      'title':
          GameSettings.languageManager.get('shelter_title', category: 'story'),
      'description':
          GameSettings.languageManager.get('shelter_desc', category: 'story'),
      'choices': [
        {
          'text':
              GameSettings.languageManager.get('continue', category: 'story'),
          'callback': _continueFromHut
        }
      ]
    };
    storyFlags['buildingHut'] = true;
  }

  // 从小屋继续
  void _continueFromHut() {
    currentEvent = null;
  }

  // 触发村庄开始建设事件
  void _triggerVillageStarted() {
    currentEvent = {
      'title':
          GameSettings.languageManager.get('village_title', category: 'story'),
      'description':
          GameSettings.languageManager.get('village_desc', category: 'story'),
      'choices': [
        {
          'text': GameSettings.languageManager
              .get('plan_village', category: 'story'),
          'callback': _planVillage
        }
      ]
    };
    storyFlags['villageStarted'] = true;
  }

  // 规划村庄
  void _planVillage() {
    // 解锁村民招募功能
    currentEvent = null;
  }

  // 新增的事件触发方法
  void _triggerTradingPostBuilt() {
    // 设置当前事件
    currentEvent = {
      'title': GameSettings.languageManager
          .get('trading_post_title', category: 'story'),
      'description': GameSettings.languageManager
          .get('trading_post_desc', category: 'story'),
      'choices': [
        {
          'text': GameSettings.languageManager
              .get('build_trading_post', category: 'story'),
          'callback': _buildTradingPost
        },
        {
          'text':
              GameSettings.languageManager.get('not_now', category: 'story'),
          'callback': _declineTradingPost
        }
      ]
    };

    // 更新故事标记
    storyFlags['tradingPostBuilt'] = true;
  }

  void _triggerMinersArrival() {
    // 设置当前事件
    currentEvent = {
      'title':
          GameSettings.languageManager.get('miners_title', category: 'story'),
      'description':
          GameSettings.languageManager.get('miners_desc', category: 'story'),
      'choices': [
        {
          'text': GameSettings.languageManager
              .get('welcome_miners', category: 'story'),
          'callback': _acceptMiners
        },
        {
          'text': GameSettings.languageManager
              .get('reject_miners', category: 'story'),
          'callback': _declineMiners
        }
      ]
    };

    // 更新故事标记
    storyFlags['minersArrived'] = true;
  }

  void _triggerSteelworksBuilt() {
    // 设置当前事件
    currentEvent = {
      'title': GameSettings.languageManager
          .get('steelworks_title', category: 'story'),
      'description': GameSettings.languageManager
          .get('steelworks_desc', category: 'story'),
      'choices': [
        {
          'text': GameSettings.languageManager
              .get('build_steelworks', category: 'story'),
          'callback': _buildSteelworks
        },
        {
          'text':
              GameSettings.languageManager.get('not_now', category: 'story'),
          'callback': _declineSteelworks
        }
      ]
    };

    // 更新故事标记
    storyFlags['steelworksBuilt'] = true;
  }

  void _triggerExpeditionReady() {
    // 设置当前事件
    currentEvent = {
      'title': GameSettings.languageManager
          .get('expedition_title', category: 'story'),
      'description': GameSettings.languageManager
          .get('expedition_desc', category: 'story'),
      'choices': [
        {
          'text': GameSettings.languageManager
              .get('prepare_expedition', category: 'story'),
          'callback': _prepareExpedition
        },
        {
          'text':
              GameSettings.languageManager.get('not_now', category: 'story'),
          'callback': _declineExpedition
        }
      ]
    };

    // 更新故事标记
    storyFlags['expeditionReady'] = true;
  }

  // 新增的事件选择回调方法
  void _buildTradingPost() {
    // 消耗资源建造交易所
    gameState.useResource('wood', 100);
    gameState.useResource('fur', 50);
    if (gameState.room['buildings'] is! Map) {
      gameState.room['buildings'] = {};
    }
    gameState.room['buildings']['trading post'] =
        (gameState.room['buildings']['trading post'] ?? 0) + 1;
    currentEvent = null;
  }

  void _declineTradingPost() {
    // 拒绝建造交易所，稍后可以重新触发
    storyFlags['tradingPostBuilt'] = false;
    currentEvent = null;
  }

  void _acceptMiners() {
    // 接受矿工，增加人口，解锁矿山
    if (gameState.population['workers'] is! Map) {
      gameState.population['workers'] = {};
    }
    gameState.population['workers']['miner'] =
        (gameState.population['workers']['miner'] ?? 0) + 5;
    gameState.population['total'] = (gameState.population['total'] as int) + 5;

    if (gameState.room['buildings'] is! Map) {
      gameState.room['buildings'] = {};
    }
    gameState.room['buildings']['mine'] =
        (gameState.room['buildings']['mine'] ?? 0) + 1;

    currentEvent = null;
  }

  void _declineMiners() {
    // 拒绝矿工，稍后可以重新触发
    storyFlags['minersArrived'] = false;
    currentEvent = null;
  }

  void _buildSteelworks() {
    // 消耗资源建造钢铁工坊
    gameState.useResource('iron', 100);
    gameState.useResource('coal', 50);
    if (gameState.room['buildings'] is! Map) {
      gameState.room['buildings'] = {};
    }
    gameState.room['buildings']['steelworks'] =
        (gameState.room['buildings']['steelworks'] ?? 0) + 1;
    currentEvent = null;
  }

  void _declineSteelworks() {
    // 拒绝建造钢铁工坊，稍后可以重新触发
    storyFlags['steelworksBuilt'] = false;
    currentEvent = null;
  }

  void _prepareExpedition() {
    // 准备远征，消耗资源
    gameState.useResource('cured meat', 200);
    gameState.useResource('steel', 100);
    gameState.useResource('medicine', 50);
    // 解锁世界地图探索功能
    gameState.worldSystem.init(); // 初始化世界地图
    currentEvent = null;
  }

  void _declineExpedition() {
    // 拒绝远征，稍后可以重新触发
    storyFlags['expeditionReady'] = false;
    currentEvent = null;
  }

  void _triggerFoundShip() {
    // 设置当前事件
    currentEvent = {
      'title': GameSettings.languageManager
          .get('mysterious_discovery_title', category: 'story'),
      'description': GameSettings.languageManager
          .get('mysterious_discovery_desc', category: 'story'),
      'choices': [
        {
          'text': GameSettings.languageManager
              .get('investigate_ship', category: 'story'),
          'callback': _investigateShip
        },
        {
          'text': GameSettings.languageManager
              .get('keep_distance', category: 'story'),
          'callback': _avoidShip
        }
      ]
    };

    // 更新故事标记
    storyFlags['foundShip'] = true;
  }

  void _investigateShip() {
    // 研究飞船，获得外星材料
    gameState.addResource('alien alloy', 20);
    gameState.addResource('circuits', 10);
    currentEvent = null;
  }

  void _avoidShip() {
    // 拒绝研究飞船，稍后可以重新触发
    storyFlags['foundShip'] = false;
    currentEvent = null;
  }

  void _triggerUnlockAlienTech() {
    // 设置当前事件
    currentEvent = {
      'title': GameSettings.languageManager
          .get('alien_tech_title', category: 'story'),
      'description': GameSettings.languageManager
          .get('alien_tech_desc', category: 'story'),
      'choices': [
        {
          'text': GameSettings.languageManager
              .get('develop_tech', category: 'story'),
          'callback': _developAlienTech
        },
        {
          'text': GameSettings.languageManager
              .get('be_cautious', category: 'story'),
          'callback': _cautionWithAlienTech
        }
      ]
    };

    // 更新故事标记
    storyFlags['unlockedAlienTech'] = true;
  }

  void _developAlienTech() {
    // 发展外星科技，解锁高级建筑
    gameState.useResource('alien alloy', 50);
    gameState.useResource('circuits', 50);
    gameState.addResource('advanced tech', 20);
    if (gameState.room['buildings'] is! Map) {
      gameState.room['buildings'] = {};
    }
    gameState.room['buildings']['spacecraft'] =
        (gameState.room['buildings']['spacecraft'] ?? 0) + 1;
    currentEvent = null;
  }

  void _cautionWithAlienTech() {
    // 谨慎对待外星科技，稍后可以重新触发
    storyFlags['unlockedAlienTech'] = false;
    currentEvent = null;
  }

  void _triggerEndgameReady() {
    // 设置当前事件
    currentEvent = {
      'title': GameSettings.languageManager
          .get('leave_or_stay_title', category: 'story'),
      'description': GameSettings.languageManager
          .get('leave_or_stay_desc', category: 'story'),
      'choices': [
        {
          'text': GameSettings.languageManager
              .get('leave_earth', category: 'story'),
          'callback': _leaveEarth
        },
        {
          'text': GameSettings.languageManager
              .get('stay_on_earth', category: 'story'),
          'callback': _stayOnEarth
        }
      ]
    };

    // 更新故事标记
    storyFlags['endgameReady'] = true;
  }

  void _leaveEarth() {
    // 选择离开地球，触发游戏结局
    currentEvent = {
      'title': GameSettings.languageManager
          .get('new_beginning_title', category: 'story'),
      'description': GameSettings.languageManager
          .get('new_beginning_desc', category: 'story'),
      'choices': [
        {
          'text':
              GameSettings.languageManager.get('restart', category: 'story'),
          'callback': () => gameState.resetGame()
        }
      ]
    };
  }

  void _stayOnEarth() {
    // 选择留在地球，游戏继续
    currentEvent = {
      'title': GameSettings.languageManager
          .get('protect_home_title', category: 'story'),
      'description': GameSettings.languageManager
          .get('protect_home_desc', category: 'story'),
      'choices': [
        {
          'text': GameSettings.languageManager
              .get('continue_game', category: 'story'),
          'callback': () => currentEvent = null
        }
      ]
    };
  }

  /// 处理故事事件选择
  void handleStoryChoice(dynamic choice) {
    if (choice is Map<String, dynamic>) {
      // 处理Map类型的选择
      if (choice['callback'] != null && choice['callback'] is Function) {
        Function callback = choice['callback'] as Function;
        callback();
      } else if (choice['effects'] != null &&
          choice['effects'] is Map<String, dynamic>) {
        _applyChoiceEffects(choice['effects'] as Map<String, dynamic>);
        currentEvent = null;
      }
    } else {
      // 处理Choice类型 - 使用duck typing
      try {
        if (choice?.effects != null && choice.effects is Map<String, dynamic>) {
          _applyChoiceEffects(choice.effects as Map<String, dynamic>);
          currentEvent = null;
        }
      } catch (e) {
        if (kDebugMode) {
          print('处理选择时出错: $e');
        }
      }
    }
  }

  /// 应用选择效果
  void _applyChoiceEffects(Map<String, dynamic> effects) {
    // 处理触发器效果
    if (effects.containsKey('trigger') && effects['trigger'] is String) {
      String triggerId = effects['trigger'] as String;

      // 根据触发器ID执行不同的操作
      switch (triggerId) {
        case 'stranger_accepted':
          _acceptStrangerHelp();
          break;
        case 'stranger_rejected':
          storyFlags['strangerLeft'] = true;
          currentEvent = null;
          break;
        default:
          // 记录未知触发器
          if (kDebugMode) {
            print('未知故事触发器: $triggerId');
          }
      }
    }

    // 处理资源效果
    if (effects.containsKey('resources') &&
        effects['resources'] is Map<String, dynamic>) {
      Map<String, dynamic> resourceEffects =
          effects['resources'] as Map<String, dynamic>;
      resourceEffects.forEach((resource, amount) {
        if (amount is int) {
          if (amount > 0) {
            gameState.addResource(resource, amount);
          } else if (amount < 0) {
            gameState.useResource(resource, -amount);
          }
        }
      });
    }

    // 处理建筑效果
    if (effects.containsKey('buildings') &&
        effects['buildings'] is Map<String, dynamic>) {
      Map<String, dynamic> buildingEffects =
          effects['buildings'] as Map<String, dynamic>;
      buildingEffects.forEach((building, amount) {
        if (amount is int && amount > 0) {
          // 添加建筑
          if (gameState.room['buildings'] is! Map) {
            gameState.room['buildings'] = {};
          }
          int currentCount =
              (gameState.room['buildings'][building] as int?) ?? 0;
          gameState.room['buildings'][building] = currentCount + amount;
        }
      });
    }
  }
}
