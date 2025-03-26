/// 游戏状态管理类，负责处理游戏的核心逻辑和数据
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'event_system.dart';
import 'trade_system.dart';
import 'dart:math';

class GameState extends ChangeNotifier {
  // 基本状态
  String currentLocation = 'room'; // 当前位置：起始为room

  // 资源管理
  Map<String, int> resources = {
    'wood': 0,
    'fur': 0,
    'meat': 0,
    'scales': 0,
    'teeth': 0,
    'leather': 0,
    'cloth': 0,
    'herbs': 0,
    'coal': 0,
    'iron': 0,
    'steel': 0,
    'sulphur': 0,
    'cured meat': 0,
    'water': 0
  };

  // 资源存储上限
  Map<String, int> resourceLimits = {
    'wood': 10000000,
    'fur': 50,
    'meat': 50,
    'scales': 30,
    'teeth': 30,
    'leather': 50,
    'cloth': 50,
    'herbs': 30,
    'coal': 50,
    'iron': 50,
    'steel': 30,
    'sulphur': 30,
    'cured meat': 50,
    'water': 50
  };

  // 建筑定义
  final Map<String, Map<String, dynamic>> availableBuildings = {
    // 基础建筑
    'trap': {
      'name': '陷阱',
      'description': '捕捉小型猎物。',
      'cost': {'wood': 10},
      'notification': '设置了陷阱。'
    },
    'cart': {
      'name': '手推车',
      'description': '增加搬运能力。',
      'cost': {'wood': 30},
      'notification': '建造了一个手推车。'
    },
    'hut': {
      'name': '小屋',
      'description': '为村民提供住所。',
      'cost': {'wood': 100},
      'notification': '建造了一个小屋，可以提供避风港。'
    },

    // 生产建筑
    'lodge': {
      'name': '狩猎营地',
      'description': '让狩猎者更有效率。',
      'cost': {'wood': 200, 'fur': 10, 'meat': 5},
      'notification': '建造了狩猎营地，狩猎效率提升。'
    },
    'trading_post': {
      'name': '交易站',
      'description': '允许与商人进行交易',
      'cost': {
        'wood': 100,
        'fur': 10,
      },
      'notification': '建造了交易站，可以和商人交易了。',
    },
    'tannery': {
      'name': '制革厂',
      'description': '将动物皮转化为皮革。',
      'cost': {'wood': 500, 'fur': 50},
      'notification': '建造了制革厂。'
    },
    'smokehouse': {
      'name': '熏肉房',
      'description': '制作熏肉保存食物。',
      'cost': {'wood': 600, 'meat': 50},
      'notification': '建造了熏肉房，可以保存食物。'
    },
    'workshop': {
      'name': '工坊',
      'description': '制作先进工具。',
      'cost': {'wood': 800, 'leather': 100, 'scales': 10},
      'notification': '建造了工坊，可以制作更复杂的东西。'
    },

    // 新增建筑
    'mine': {
      'name': '矿井',
      'description': '开采铁矿和煤炭。',
      'cost': {'wood': 300, 'leather': 50},
      'notification': '建造了矿井，可以开采矿物。',
      'requires': {'workshop': 1} // 需要先建造工坊
    },
    'armoury': {
      'name': '军械库',
      'description': '制作武器和防具。',
      'cost': {'wood': 600, 'steel': 50, 'leather': 100},
      'notification': '建造了军械库，可以制作武器。',
      'requires': {'workshop': 1}
    },
    'storehouse': {
      'name': '仓库',
      'description': '增加资源存储上限。',
      'cost': {'wood': 400, 'leather': 50},
      'notification': '建造了仓库，可以存储更多资源。'
    },
    'watermill': {
      'name': '水磨',
      'description': '提高资源加工效率。',
      'cost': {'wood': 500, 'iron': 50, 'leather': 50},
      'notification': '建造了水磨，加工效率提升。',
      'requires': {'workshop': 1}
    },
    'steelworks': {
      'name': '炼钢厂',
      'description': '将铁转化为钢。',
      'cost': {'iron': 100, 'coal': 100, 'leather': 50},
      'notification': '建造了炼钢厂，可以生产钢材。',
      'requires': {'mine': 1}
    },
    'school': {
      'name': '学校',
      'description': '提高村民工作效率。',
      'cost': {'wood': 600, 'leather': 100, 'steel': 50},
      'notification': '建造了学校，村民可以学习新知识。',
      'requires': {'workshop': 1}
    }
  };

  // 房间状态
  Map<String, dynamic> room = {
    'temperature': 'cold', // 房间温度
    'fire': 0, // 火堆状态 (0-不活跃, 1-噼啪作响, 2-燃烧, 3-咆哮)
    'buildings': {}, // 已建造的建筑
  };

  // 村民状态
  Map<String, dynamic> population = {
    'workers': {}, // 工人数量，按类型
    'total': 0, // 总人口
    'max': 0, // 最大人口
    'happiness': 100, // 村民幸福度
  };

  // 村民类型定义
  final Map<String, Map<String, dynamic>> villagerTypes = {
    'gatherer': {
      'name': '采集者',
      'description': '收集木材和食物',
      'baseEfficiency': 1.0,
      'resourceTypes': ['wood', 'meat', 'fur'],
      'cost': {'meat': 10, 'water': 5},
    },
    'hunter': {
      'name': '猎人',
      'description': '专门狩猎动物',
      'baseEfficiency': 1.5,
      'resourceTypes': ['meat', 'fur', 'leather'],
      'cost': {'meat': 15, 'water': 5},
    },
    'builder': {
      'name': '建造者',
      'description': '建造和维护建筑',
      'baseEfficiency': 1.2,
      'resourceTypes': ['wood'],
      'cost': {'meat': 12, 'water': 5},
    },
    'craftsman': {
      'name': '工匠',
      'description': '制作高级物品',
      'baseEfficiency': 1.3,
      'resourceTypes': ['leather', 'cloth', 'steel'],
      'cost': {'meat': 20, 'water': 5},
    },
  };

  // 玩家状态
  Map<String, dynamic> character = {
    'health': 10, // 生命值
    'perks': [], // 特性
  };

  // 世界状态
  Map<String, dynamic> world = {
    'explored': 0, // 探索程度
    'locations': {}, // 已发现的位置
  };

  // 游戏进度
  bool storeOpened = false; // 商店是否开启
  bool outsideUnlocked = false; // 外部世界是否解锁
  bool craftingUnlocked = false; // 制作功能是否解锁

  // 建筑等级
  Map<String, int> buildingLevels = {};

  // 建筑维护成本
  final Map<String, Map<String, dynamic>> buildingMaintenance = {
    'mine': {
      'wood': 2,
      'leather': 1,
      'interval': 30, // 维护间隔（秒）
    },
    'steelworks': {
      'coal': 1,
      'wood': 2,
      'interval': 30,
    },
    'school': {
      'wood': 1,
      'leather': 1,
      'interval': 60,
    },
    'watermill': {
      'wood': 2,
      'interval': 45,
    },
  };

  // 建筑升级效果
  Map<String, Map<String, dynamic>> getBuildingUpgradeEffects(
      String buildingId, int level) {
    switch (buildingId) {
      case 'mine':
        return {
          'effects': {
            'production': 1.0 + (level - 1) * 0.2, // 每级增加20%产量
            'storage': 50 * level, // 每级增加50存储上限
          },
          'cost': {
            'wood': 300 + level * 100,
            'leather': 50 + level * 20,
          },
        };
      case 'steelworks':
        return {
          'effects': {
            'production': 1.0 + (level - 1) * 0.25,
            'efficiency': 1.0 + (level - 1) * 0.15, // 每级减少15%资源消耗
          },
          'cost': {
            'iron': 100 + level * 50,
            'coal': 100 + level * 30,
            'leather': 50 + level * 20,
          },
        };
      default:
        return {
          'effects': {
            'production': 1.0,
          },
          'cost': availableBuildings[buildingId]?['cost'] ?? {},
        };
    }
  }

  // 检查建筑是否可以升级
  bool canUpgradeBuilding(String buildingId) {
    if (!availableBuildings.containsKey(buildingId)) return false;

    int currentLevel = buildingLevels[buildingId] ?? 1;
    if (currentLevel >= 3) return false; // 最高3级

    Map<String, dynamic> upgradeCost =
        getBuildingUpgradeEffects(buildingId, currentLevel + 1)['cost']!;

    // 检查资源是否足够
    for (var entry in upgradeCost.entries) {
      if ((resources[entry.key] ?? 0) < (entry.value as int)) {
        return false;
      }
    }

    return true;
  }

  // 升级建筑
  bool upgradeBuilding(String buildingId) {
    if (!canUpgradeBuilding(buildingId)) return false;

    int currentLevel = buildingLevels[buildingId] ?? 1;
    var upgradeEffects =
        getBuildingUpgradeEffects(buildingId, currentLevel + 1);
    Map<String, dynamic> upgradeCost = upgradeEffects['cost']!;

    // 消耗资源
    for (var entry in upgradeCost.entries) {
      useResource(entry.key, entry.value as int);
    }

    // 更新等级
    buildingLevels[buildingId] = currentLevel + 1;

    // 应用升级效果
    Map<String, dynamic> effects = upgradeEffects['effects']!;
    applyBuildingEffects(buildingId, effects);

    return true;
  }

  // 应用建筑效果
  void applyBuildingEffects(String buildingId, Map<String, dynamic> effects) {
    // 根据建筑类型应用不同的效果
    switch (buildingId) {
      case 'mine':
        resourceProductionMultipliers['iron'] = effects['production'] as double;
        resourceLimits['iron'] = (effects['storage'] as int);
        break;
      case 'steelworks':
        resourceProductionMultipliers['steel'] =
            effects['production'] as double;
        resourceEfficiency['coal'] = effects['efficiency'] as double;
        break;
      // ... 其他建筑的效果应用 ...
    }
  }

  // 更新建筑维护
  void updateBuildingMaintenance() {
    room['buildings'].forEach((buildingId, count) {
      if (count > 0 && buildingMaintenance.containsKey(buildingId)) {
        Map<String, dynamic> maintenance = buildingMaintenance[buildingId]!;
        int interval = maintenance['interval'] as int;

        // 检查是否需要维护
        if (DateTime.now().second % interval == 0) {
          bool canMaintain = true;
          Map<String, int> cost = {};

          // 计算维护成本
          maintenance.forEach((resource, amount) {
            if (resource != 'interval') {
              // 修复类型转换问题
              int resourceAmount = (amount is int) ? amount : amount.toInt();
              int required = resourceAmount * (count as int);
              if ((resources[resource] ?? 0) < required) {
                canMaintain = false;
              }
              cost[resource] = required;
            }
          });

          if (canMaintain) {
            // 扣除维护资源
            cost.forEach((resource, amount) {
              useResource(resource, amount);
            });
          } else {
            // 建筑效率降低
            buildingEfficiencyPenalty[buildingId] = 0.5;
          }
        }
      }
    });
  }

  // 建筑效率惩罚
  Map<String, double> buildingEfficiencyPenalty = {};

  final EventSystem eventSystem = EventSystem();
  final TradeSystem tradeSystem = TradeSystem();
  GameEvent? currentEvent;
  Timer? eventTimer;

  // 初始化事件系统
  void initEventSystem() {
    eventTimer?.cancel();
    eventTimer = Timer.periodic(const Duration(minutes: 3), (timer) {
      checkForEvents();
    });
  }

  // 检查是否触发新事件
  void checkForEvents() {
    if (currentEvent != null) return;

    GameEvent? newEvent = eventSystem.getRandomEvent(this);
    if (newEvent != null) {
      currentEvent = newEvent;
      if (newEvent.choices == null) {
        eventSystem.applyEventEffects(newEvent.effects, this);
        currentEvent = null;
      }
      notifyListeners();
    }
  }

  // 处理事件选择
  void makeEventChoice(Choice choice) {
    if (currentEvent == null) return;

    if (eventSystem.canChoose(choice, this)) {
      eventSystem.applyEventEffects(choice.effects, this);
      currentEvent = null;
      notifyListeners();
    }
  }

  // 检查是否可以购买
  bool canBuy(String itemId, int amount) {
    if (!storeOpened) return false;

    int totalCost = tradeSystem.calculateBuyPrice(itemId, amount);

    if ((resources['money'] ?? 0) < totalCost) return false;

    int currentAmount = resources[itemId] ?? 0;
    int limit = calculateResourceLimit(itemId);
    if (currentAmount + amount > limit) return false;

    return true;
  }

  // 检查是否可以出售
  bool canSell(String itemId, int amount) {
    if (!storeOpened) return false;
    return (resources[itemId] ?? 0) >= amount;
  }

  // 购买物品
  bool buyItem(String itemId, int amount) {
    if (!canBuy(itemId, amount)) return false;

    int totalCost = tradeSystem.calculateBuyPrice(itemId, amount);
    useResource('money', totalCost);
    addResource(itemId, amount);
    notifyListeners();

    return true;
  }

  // 出售物品
  bool sellItem(String itemId, int amount) {
    if (!canSell(itemId, amount)) return false;

    int totalGain = tradeSystem.calculateSellPrice(itemId, amount);
    useResource(itemId, amount);
    addResource('money', totalGain);
    notifyListeners();

    return true;
  }

  // 狩猎相关的配置
  final Map<String, Map<String, dynamic>> huntingOutcomes = {
    'small_game': {
      'name': '小型猎物',
      'outcomes': {
        'meat': {'min': 1, 'max': 3},
        'fur': {'min': 0, 'max': 2},
      },
      'time': 3, // 狩猎时间（秒）
    },
    'large_game': {
      'name': '大型猎物',
      'outcomes': {
        'meat': {'min': 3, 'max': 8},
        'fur': {'min': 2, 'max': 4},
        'teeth': {'min': 0, 'max': 2},
      },
      'time': 6,
      'requires': {'weapons': 1}, // 需要武器
    },
    'dangerous_game': {
      'name': '危险猎物',
      'outcomes': {
        'meat': {'min': 5, 'max': 12},
        'fur': {'min': 3, 'max': 7},
        'teeth': {'min': 1, 'max': 3},
        'scales': {'min': 0, 'max': 2},
      },
      'time': 10,
      'requires': {'weapons': 2}, // 需要更好的武器
    },
  };

  // 狩猎状态
  bool isHunting = false;
  String? currentHuntType;
  Timer? huntingTimer;
  int huntingTimeLeft = 0;

  // 开始狩猎
  bool startHunting(String huntType) {
    if (isHunting) return false;

    var huntConfig = huntingOutcomes[huntType];
    if (huntConfig == null) return false;

    // 检查武器要求
    if (huntConfig.containsKey('requires')) {
      var requires = huntConfig['requires'] as Map<String, int>;
      if ((room['buildings']?['weapons'] ?? 0) < (requires['weapons'] ?? 0)) {
        return false;
      }
    }

    isHunting = true;
    currentHuntType = huntType;
    huntingTimeLeft = huntConfig['time'] as int;

    // 启动狩猎计时器
    huntingTimer?.cancel();
    huntingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      huntingTimeLeft--;
      if (huntingTimeLeft <= 0) {
        _completeHunting();
        timer.cancel();
      }
      notifyListeners();
    });

    notifyListeners();
    return true;
  }

  // 完成狩猎
  void _completeHunting() {
    if (!isHunting || currentHuntType == null) return;

    var huntConfig = huntingOutcomes[currentHuntType]!;
    var outcomes = huntConfig['outcomes'] as Map<String, dynamic>;

    // 计算狩猎结果
    outcomes.forEach((resource, range) {
      int min = range['min'] as int;
      int max = range['max'] as int;
      int amount = min + Random().nextInt(max - min + 1);

      if (amount > 0) {
        addResource(resource, amount);
      }
    });

    // 重置狩猎状态
    isHunting = false;
    currentHuntType = null;
    huntingTimer?.cancel();
    huntingTimer = null;

    notifyListeners();
  }

  // 合并所有清理逻辑到一个 dispose 方法
  @override
  void dispose() {
    eventTimer?.cancel();
    huntingTimer?.cancel();
    super.dispose();
  }

  GameState();

  // 从JSON创建游戏状态
  GameState.fromJson(Map<String, dynamic> json) {
    currentLocation = json['currentLocation'] ?? 'room';
    resources = Map<String, int>.from(json['resources'] ?? {});
    room = Map<String, dynamic>.from(json['room'] ?? {});
    character = Map<String, dynamic>.from(json['character'] ?? {});
    world = Map<String, dynamic>.from(json['world'] ?? {});
    population = Map<String, dynamic>.from(json['population'] ??
        {'workers': {}, 'total': 0, 'max': 0, 'happiness': 100});
    storeOpened = json['storeOpened'] ?? false;
    outsideUnlocked = json['outsideUnlocked'] ?? false;
    craftingUnlocked = json['craftingUnlocked'] ?? false;
    buildingLevels = Map<String, int>.from(json['buildingLevels'] ?? {});
    buildingEfficiencyPenalty =
        Map<String, double>.from(json['buildingEfficiencyPenalty'] ?? {});
  }

  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'currentLocation': currentLocation,
      'resources': resources,
      'room': room,
      'population': population,
      'character': character,
      'world': world,
      'storeOpened': storeOpened,
      'outsideUnlocked': outsideUnlocked,
      'craftingUnlocked': craftingUnlocked,
      'buildingLevels': buildingLevels,
      'buildingEfficiencyPenalty': buildingEfficiencyPenalty,
    };
  }

  // 添加资源
  void addResource(String name, int amount) {
    if (resources.containsKey(name)) {
      int currentAmount = resources[name] ?? 0;
      int limit = calculateResourceLimit(name);
      resources[name] = (currentAmount + amount).clamp(0, limit);
    } else {
      resources[name] = amount;
    }
  }

  // 消耗资源
  bool useResource(String name, int amount) {
    if (!resources.containsKey(name) || (resources[name] ?? 0) < amount) {
      return false;
    }
    resources[name] = (resources[name] ?? 0) - amount;
    return true;
  }

  // 检查是否有足够的资源建造建筑
  bool canBuild(String buildingId) {
    if (!availableBuildings.containsKey(buildingId)) {
      return false;
    }

    // 检查前置条件
    Map<String, dynamic> building = availableBuildings[buildingId]!;
    if (building.containsKey('requires')) {
      Map<String, int> requires =
          Map<String, int>.from(building['requires'] as Map);
      for (var entry in requires.entries) {
        if ((room['buildings']?[entry.key] ?? 0) < entry.value) {
          return false;
        }
      }
    }

    // 检查资源是否足够
    Map<String, dynamic> cost = building['cost'] as Map<String, dynamic>;
    for (var resource in cost.keys) {
      int required = cost[resource] as int;
      if ((resources[resource] ?? 0) < required) {
        return false;
      }
    }

    return true;
  }

  // 建造建筑
  bool buildStructure(String buildingId) {
    if (!canBuild(buildingId)) return false;

    // 消耗资源
    Map<String, dynamic> cost =
        availableBuildings[buildingId]!['cost'] as Map<String, dynamic>;
    for (var resource in cost.keys) {
      useResource(resource, cost[resource] as int);
    }

    // 更新建筑数量
    if (room['buildings'] is! Map) {
      room['buildings'] = {};
    }
    room['buildings'][buildingId] = (room['buildings'][buildingId] ?? 0) + 1;

    // 特殊建筑效果
    if (buildingId == 'trading_post') {
      storeOpened = true; // 直接解锁交易功能
    }

    notifyListeners();
    return true;
  }

  // 获取建筑数量
  int getBuildingCount(String buildingId) {
    if (room['buildings'] is! Map) {
      return 0;
    }
    return room['buildings'][buildingId] ?? 0;
  }

  // 检查是否可以招募新村民
  bool canRecruitVillager(String type) {
    if (!villagerTypes.containsKey(type)) {
      return false;
    }

    // 检查人口上限
    if (population['total'] >= population['max']) {
      return false;
    }

    // 检查资源是否足够
    Map<String, dynamic> cost =
        villagerTypes[type]!['cost'] as Map<String, dynamic>;
    for (var resource in cost.keys) {
      int required = cost[resource] as int;
      if ((resources[resource] ?? 0) < required) {
        return false;
      }
    }

    return true;
  }

  // 招募新村民
  bool recruitVillager(String type) {
    if (!canRecruitVillager(type)) {
      return false;
    }

    // 消耗资源
    Map<String, dynamic> cost =
        villagerTypes[type]!['cost'] as Map<String, dynamic>;
    for (var resource in cost.keys) {
      useResource(resource, cost[resource] as int);
    }

    // 更新村民数量
    if (population['workers'] is! Map) {
      population['workers'] = {};
    }
    population['workers'][type] = (population['workers'][type] ?? 0) + 1;
    population['total'] = (population['total'] ?? 0) + 1;

    // 更新最大人口
    int hutCount = getBuildingCount('hut');
    population['max'] = hutCount * 2; // 每个小屋可以容纳2个村民

    return true;
  }

  // 计算资源上限
  int calculateResourceLimit(String resourceName) {
    int baseLimit = resourceLimits[resourceName] ?? 100;
    int multiplier = 1;

    // 仓库增加所有资源上限
    int storehouseCount = getBuildingCount('storehouse');
    multiplier += storehouseCount; // 每个仓库使上限翻倍

    // 特殊建筑对特定资源的影响（考虑建筑等级）
    switch (resourceName) {
      case 'iron':
      case 'coal':
        int mineCount = getBuildingCount('mine');
        int mineLevel = buildingLevels['mine'] ?? 1;
        multiplier += mineCount * mineLevel;
        break;
      case 'steel':
        int steelworksCount = getBuildingCount('steelworks');
        int steelworksLevel = buildingLevels['steelworks'] ?? 1;
        multiplier += steelworksCount * steelworksLevel;
        break;
    }

    return baseLimit * multiplier;
  }

  // 获取资源存储状态
  Map<String, Map<String, int>> getResourceStorage() {
    Map<String, Map<String, int>> storage = {};
    resources.forEach((resource, amount) {
      storage[resource] = {
        'amount': amount,
        'limit': calculateResourceLimit(resource)
      };
    });
    return storage;
  }

  // 计算村民工作效率
  double calculateVillagerEfficiency(String type) {
    if (!villagerTypes.containsKey(type)) {
      return 0.0;
    }

    double baseEfficiency = villagerTypes[type]!['baseEfficiency'] as double;

    // 建筑加成
    switch (type) {
      case 'hunter':
        if (getBuildingCount('lodge') > 0) {
          baseEfficiency *= 1.5; // 狩猎营地提升50%效率
        }
        break;
      case 'gatherer':
        if (getBuildingCount('cart') > 0) {
          baseEfficiency *= 1.3; // 手推车提升30%效率
        }
        break;
      case 'craftsman':
        if (getBuildingCount('workshop') > 0) {
          baseEfficiency *= 1.4; // 工坊提升40%效率
        }
        break;
    }

    // 学校提供全局效率加成
    int schoolCount = getBuildingCount('school');
    if (schoolCount > 0) {
      baseEfficiency *= (1 + 0.1 * schoolCount); // 每所学校提供10%效率加成
    }

    // 水磨提供全局效率加成
    int watermillCount = getBuildingCount('watermill');
    if (watermillCount > 0) {
      baseEfficiency *= (1 + 0.15 * watermillCount); // 每个水磨提供15%效率加成
    }

    // 根据幸福度调整效率
    double happinessMultiplier = population['happiness'] / 100.0;

    // 考虑建筑维护状态
    double maintenanceMultiplier = 1.0;
    room['buildings'].forEach((buildingId, count) {
      if (count > 0 && buildingEfficiencyPenalty.containsKey(buildingId)) {
        maintenanceMultiplier *= buildingEfficiencyPenalty[buildingId]!;
      }
    });

    return baseEfficiency * happinessMultiplier * maintenanceMultiplier;
  }

  // 更新村民工作
  void updateVillagerWork() {
    Map<String, int> production = calculateVillagerProduction();

    // 特殊建筑效果
    int steelworksCount = getBuildingCount('steelworks');
    if (steelworksCount > 0 &&
        (resources['iron'] ?? 0) >= 1 &&
        (resources['coal'] ?? 0) >= 1) {
      // 炼钢厂：消耗铁和煤，生产钢
      if (useResource('iron', 1) && useResource('coal', 1)) {
        production['steel'] = (production['steel'] ?? 0) + 1;
      }
    }

    // 添加资源（考虑存储上限）
    production.forEach((resource, amount) {
      addResource(resource, amount);
    });

    // 更新幸福度
    updateVillagerHappiness();
  }

  // 更新村民幸福度
  void updateVillagerHappiness() {
    int total = population['total'] ?? 0;
    if (total == 0) return;

    // 基础幸福度
    double baseHappiness = 100.0;

    // 根据食物供应调整
    int meatSupply = resources['meat'] ?? 0;
    double foodHappiness = (meatSupply / total).clamp(0.0, 1.0) * 50.0;

    // 根据住所调整
    int hutCount = getBuildingCount('hut');
    double housingHappiness = (hutCount * 2 / total).clamp(0.0, 1.0) * 50.0;

    // 更新幸福度
    population['happiness'] =
        (baseHappiness + foodHappiness + housingHappiness).clamp(0.0, 100.0);
  }

  // 村民工作产出
  Map<String, int> calculateVillagerProduction() {
    Map<String, int> production = {};

    population['workers'].forEach((type, count) {
      if (count > 0) {
        double efficiency = calculateVillagerEfficiency(type);
        List<String> resourceTypes =
            villagerTypes[type]!['resourceTypes'] as List<String>;

        for (var resource in resourceTypes) {
          int amount = (efficiency * count).round();
          production[resource] = (production[resource] ?? 0) + amount;
        }
      }
    });

    return production;
  }

  // 添加资源生产和效率相关的字段
  Map<String, double> resourceProductionMultipliers = {
    'iron': 1.0,
    'steel': 1.0,
    'wood': 1.0,
    'coal': 1.0,
  };

  Map<String, double> resourceEfficiency = {
    'iron': 1.0,
    'steel': 1.0,
    'wood': 1.0,
    'coal': 1.0,
  };
}
