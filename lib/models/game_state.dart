// 游戏状态管理类，负责处理游戏的核心逻辑和数据
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'event_system.dart';
import 'trade_system.dart';
import 'dart:math';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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
    'trap': {
      'name': '陷阱',
      'description': '捕捉野生动物',
      'cost': {'wood': 10},
      'notification': '设置了陷阱。',
    },
    'cart': {
      'name': '货车',
      'description': '增加携带容量',
      'cost': {'wood': 30},
      'notification': '货车可以携带更多物资了。',
      'effects': {'storage': 50},
    },
    'hut': {
      'name': '小屋',
      'description': '为村民提供住所',
      'cost': {
        'wood': 100,
        'fur': 10,
      },
      'notification': '建造了一个小屋。',
      'effects': {'population': 1},
    },
    'lodge': {
      'name': '猎人小屋',
      'description': '训练熟练的猎人',
      'cost': {
        'wood': 200,
        'fur': 10,
        'meat': 5,
      },
      'notification': '猎人有了栖身之所。',
      'requires': {
        'buildings': {'hut': 1}
      },
    },
    'trading_post': {
      'name': '交易站',
      'description': '与商人交易物资',
      'cost': {
        'wood': 100,
        'fur': 10,
      },
      'notification': '商人可以在这里交易了。',
    },
    'tannery': {
      'name': '制革厂',
      'description': '将毛皮制成皮革',
      'cost': {
        'wood': 100,
        'fur': 50,
      },
      'notification': '皮革工人开始工作了。',
      'requires': {
        'buildings': {'trading_post': 1}
      },
    },
    'smokehouse': {
      'name': '熏肉房',
      'description': '保存肉类',
      'cost': {
        'wood': 100,
        'meat': 50,
      },
      'notification': '肉可以储存更久了。',
      'effects': {'meat_storage': 50},
    },
    'workshop': {
      'name': '工坊',
      'description': '制作高级工具',
      'cost': {
        'wood': 200,
        'leather': 20,
      },
      'notification': '工匠有了工作的地方。',
      'requires': {
        'buildings': {'tannery': 1}
      },
    },
    'steelworks': {
      'name': '炼钢厂',
      'description': '将铁转化为钢',
      'cost': {
        'wood': 300,
        'iron': 100,
        'coal': 50,
      },
      'notification': '钢铁生产开始了。',
      'requires': {
        'buildings': {'workshop': 1}
      },
    },
    'armoury': {
      'name': '军械库',
      'description': '制造武器和盔甲',
      'cost': {
        'wood': 400,
        'steel': 50,
      },
      'notification': '可以制造更好的武器了。',
      'requires': {
        'buildings': {'steelworks': 1}
      },
    },
    'well': {
      'name': '水井',
      'description': '提供稳定的水源',
      'cost': {'wood': 50},
      'notification': '水井建好了。',
      'effects': {'water_production': 1}, // 每次产出1单位水
    },
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
    'discovered_locations': [],
    'location_info': {},
  };

  // 游戏进度
  bool storeOpened = false; // 商店是否开启
  bool outsideUnlocked = false; // 外部世界是否解锁
  bool craftingUnlocked = false; // 制作功能是否解锁

  // 建筑等级
  Map<String, int> buildingLevels = {};

  // 建筑维护成本
  Map<String, Map<String, dynamic>> buildingMaintenance = {
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
    applyBuildingEffects(buildingId, false);

    return true;
  }

  // 应用建筑效果
  void applyBuildingEffects(String buildingId, [bool remove = false]) {
    var building = availableBuildings[buildingId];
    if (building == null) {
      return;
    }

    var buildingEffects = building['effects'];
    if (buildingEffects == null || buildingEffects is! Map<String, dynamic>) {
      return;
    }

    int multiplier = remove ? -1 : 1;

    buildingEffects.forEach((key, value) {
      if (value is! int) return;

      switch (key) {
        case 'storage':
          resourceLimits.forEach((resource, _) {
            resourceLimits[resource] =
                (resourceLimits[resource] ?? 100) + (value * multiplier);
          });
          break;
        case 'population':
          population['max'] = (population['max'] as int) + (value * multiplier);
          break;
        case 'meat_storage':
          resourceLimits['meat'] =
              (resourceLimits['meat'] ?? 100) + (value * multiplier);
          resourceLimits['cured meat'] =
              (resourceLimits['cured meat'] ?? 100) + (value * multiplier);
          break;
      }
    });
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
              int required = amount as int;
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

  // 添加水资源生产计时器
  Timer? _waterTimer;

  // 在构造函数中初始化水资源生产
  GameState() {
    // 初始化基本状态
    currentLocation = 'room'; // 确保初始化当前位置

    // 初始化资源
    resources = {
      'wood': 0,
      'water': 0,
      // ... 其他资源初始化 ...
    };

    // 初始化定时器
    _waterTimer = Timer.periodic(Duration(seconds: 10), (timer) {
      if (room['buildings']?['well'] != null) {
        _produceWater();
      }
    });

    // ... 其他初始化代码 ...
  }

  // 水资源生产方法
  void _produceWater() {
    int wellCount = room['buildings']?['well'] ?? 0;
    if (wellCount > 0) {
      int waterProduction = wellCount; // 每个水井产生1单位水
      addResource('water', waterProduction);

      // 添加日志
      if (waterProduction > 0) {
        addLog('水井产出了 $waterProduction 单位水。');
      }
    }
  }

  // 在外面探索时获取水的方法
  void gatherWater() {
    if (!isGatheringWater) {
      isGatheringWater = true;

      // 收集水需要30秒
      Future.delayed(Duration(seconds: 30), () {
        // 随机获得1-3单位水
        int waterFound = Random().nextInt(3) + 1;
        addResource('water', waterFound);
        addLog('收集到了 $waterFound 单位水。');
        isGatheringWater = false;
        notifyListeners();
      });

      notifyListeners();
    }
  }

  // 添加状态标记
  bool isGatheringWater = false;

  // 合并所有清理逻辑到一个 dispose 方法
  @override
  void dispose() {
    eventTimer?.cancel();
    huntingTimer?.cancel();
    _waterTimer?.cancel();
    super.dispose();
  }

  // 添加日志列表
  final List<String> gameLogs = [];

  // 添加日志方法
  void addLog(String message) {
    gameLogs.add(message);
    notifyListeners();
  }

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
    if (!isBuildingUnlocked(buildingId)) return false;

    Map<String, dynamic> cost =
        availableBuildings[buildingId]!['cost'] as Map<String, dynamic>;

    for (var entry in cost.entries) {
      if ((resources[entry.key] ?? 0) < (entry.value as int)) {
        return false;
      }
    }

    return true;
  }

  // 建造建筑
  bool buildStructure(String buildingId) {
    if (!canBuild(buildingId)) {
      return false;
    }

    var building = availableBuildings[buildingId];
    if (building == null) {
      return false;
    }

    var cost = building['cost'];
    if (cost is Map<String, dynamic>) {
      for (var entry in cost.entries) {
        if (entry.value is int) {
          useResource(entry.key, entry.value);
        }
      }
    }

    // 更新建筑数量
    if (room['buildings'] is! Map) {
      room['buildings'] = {};
    }
    room['buildings'][buildingId] = (room['buildings'][buildingId] ?? 0) + 1;

    // 应用建筑效果
    applyBuildingEffects(buildingId, false);

    // 特殊建筑效果
    if (buildingId == 'trading_post') {
      storeOpened = true;
    } else if (buildingId == 'trap' && !outsideUnlocked) {
      outsideUnlocked = true;
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

  // 添加建筑解锁检查
  bool isBuildingUnlocked(String buildingId) {
    var building = availableBuildings[buildingId];
    if (building == null) return false;

    // 检查前置建筑要求
    if (building.containsKey('requires')) {
      var requires = building['requires'] as Map<String, dynamic>;
      if (requires.containsKey('buildings')) {
        Map<String, int> requiredBuildings =
            Map<String, int>.from(requires['buildings']);
        for (var entry in requiredBuildings.entries) {
          if ((room['buildings']?[entry.key] ?? 0) < entry.value) {
            return false;
          }
        }
      }
    }

    return true;
  }

  // 添加存档相关字段
  static const String SAVE_DIRECTORY = 'saves';
  static const int MAX_SAVE_SLOTS = 3;
  String currentSaveSlot = 'slot1';

  // 获取存档目录
  Future<String> getSaveDirectory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('saveDirectory') ?? 'saves';
  }

  // 设置存档目录
  Future<void> setSaveDirectory(String directory) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saveDirectory', directory);
  }

  // 获取所有存档槽位信息
  Future<List<Map<String, dynamic>>> getAllSaveSlots() async {
    List<Map<String, dynamic>> slots = [];
    for (int i = 1; i <= MAX_SAVE_SLOTS; i++) {
      String slotKey = 'slot$i';
      final prefs = await SharedPreferences.getInstance();
      String? saveData = prefs.getString(slotKey);
      if (saveData != null) {
        try {
          Map<String, dynamic> data = jsonDecode(saveData);
          slots.add({
            'slot': slotKey,
            'timestamp': data['timestamp'] ?? '',
            'location': data['currentLocation'] ?? 'room',
            'population': data['population']?['total'] ?? 0,
          });
        } catch (e) {
          print('Error reading save slot $slotKey: $e');
        }
      } else {
        slots.add({
          'slot': slotKey,
          'timestamp': '',
          'location': '',
          'population': 0,
        });
      }
    }
    return slots;
  }

  // 修改保存游戏方法
  Future<void> saveGame() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saveData = toJson();
      saveData['timestamp'] = DateTime.now().toIso8601String();

      // 保存到当前槽位
      await prefs.setString(currentSaveSlot, jsonEncode(saveData));

      // 保存存档目录
      await setSaveDirectory(SAVE_DIRECTORY);

      notifyListeners();
    } catch (e) {
      print('Error saving game: $e');
      rethrow;
    }
  }

  // 修改加载游戏方法
  Future<bool> loadGame([String? slot]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String saveSlot = slot ?? currentSaveSlot;

      print('Loading game from slot: $saveSlot');

      // 检查是否有存档
      if (!prefs.containsKey(saveSlot)) {
        print('No save data found in slot: $saveSlot');
        return false;
      }

      // 加载存档数据
      String? saveDataString = prefs.getString(saveSlot);
      if (saveDataString == null) {
        print('Save data is null for slot: $saveSlot');
        return false;
      }

      print('Found save data, attempting to decode...');
      final saveData = jsonDecode(saveDataString);
      print('Successfully decoded save data');

      // 更新当前槽位
      currentSaveSlot = saveSlot;
      print('Updated current save slot to: $currentSaveSlot');

      // 加载基本游戏状态
      currentLocation = saveData['currentLocation'] ?? 'room';
      outsideUnlocked = saveData['outsideUnlocked'] ?? false;
      storeOpened = saveData['storeOpened'] ?? false;
      print(
          'Loaded basic game state: location=$currentLocation, outsideUnlocked=$outsideUnlocked, storeOpened=$storeOpened');

      // 加载资源
      resources = Map<String, int>.from(saveData['resources'] ?? {});
      print('Loaded resources: ${resources.length} items');

      // 加载房间状态
      room = Map<String, dynamic>.from(saveData['room'] ?? {});
      print('Loaded room state: ${room.length} items');

      // 加载建筑等级
      buildingLevels = Map<String, int>.from(saveData['buildingLevels'] ?? {});
      print('Loaded building levels: ${buildingLevels.length} items');

      // 加载人口信息
      population = Map<String, dynamic>.from(saveData['population'] ??
          {'workers': {}, 'total': 0, 'max': 0, 'happiness': 100});
      print(
          'Loaded population: total=${population['total']}, max=${population['max']}');

      // 加载建筑维护信息
      buildingMaintenance = Map<String, Map<String, dynamic>>.from(
        saveData['buildingMaintenance'] ?? {},
      );
      print('Loaded building maintenance: ${buildingMaintenance.length} items');

      // 加载事件系统状态
      if (saveData['eventSystem'] != null) {
        eventSystem.fromJson(saveData['eventSystem']);
        print('Loaded event system state');
      }

      // 加载交易系统状态
      if (saveData['tradeSystem'] != null) {
        tradeSystem.fromJson(saveData['tradeSystem']);
        print('Loaded trade system state');
      }

      print('Game loaded successfully');
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      print('Error loading game: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }

  // 检查是否有存档
  Future<bool> hasSaveGame() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      bool hasSave = prefs.containsKey(currentSaveSlot);
      print('Checking for save game in slot $currentSaveSlot: $hasSave');
      return hasSave;
    } catch (e) {
      print('Error checking for save game: $e');
      return false;
    }
  }

  // 删除指定槽位的存档
  Future<void> deleteSaveSlot(String slot) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      print('Attempting to delete save slot: $slot');

      // 检查存档是否存在
      if (!prefs.containsKey(slot)) {
        print('Save slot $slot does not exist');
        return;
      }

      // 如果删除的是当前存档槽位，重置当前槽位
      if (slot == currentSaveSlot) {
        currentSaveSlot = 'slot1';
        print('Reset current save slot to slot1');
      }

      // 删除存档
      bool success = await prefs.remove(slot);
      print('Delete save slot $slot: ${success ? 'success' : 'failed'}');

      // 强制刷新 SharedPreferences
      await prefs.reload();
      print('Reloaded SharedPreferences');

      // 验证存档是否已被删除
      if (prefs.containsKey(slot)) {
        print('Warning: Save slot $slot still exists after deletion');
        // 尝试再次删除
        await prefs.remove(slot);
        await prefs.reload();
      }

      // 通知监听器更新UI
      notifyListeners();
      print('Notified listeners of save slot deletion');
    } catch (e) {
      print('Error deleting save slot: $e');
      rethrow;
    }
  }

  // 删除当前存档
  Future<void> deleteSaveGame() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(currentSaveSlot);
    notifyListeners();
  }

  // 清除所有存档
  Future<void> clearAllSaveSlots() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      print('Starting to clear all save slots...');

      // 删除所有存档槽位
      for (int i = 1; i <= MAX_SAVE_SLOTS; i++) {
        String slotKey = 'slot$i';
        print('Attempting to delete save slot: $slotKey');

        // 检查存档是否存在
        if (!prefs.containsKey(slotKey)) {
          print('Save slot $slotKey does not exist, skipping...');
          continue;
        }

        // 删除存档
        bool success = await prefs.remove(slotKey);
        print('Delete save slot $slotKey: ${success ? 'success' : 'failed'}');

        // 验证存档是否已被删除
        if (prefs.containsKey(slotKey)) {
          print('Warning: Save slot $slotKey still exists after deletion');
          // 尝试再次删除
          await prefs.remove(slotKey);
          await prefs.reload();

          // 再次验证
          if (prefs.containsKey(slotKey)) {
            print(
                'Error: Failed to delete save slot $slotKey after multiple attempts');
            throw Exception('Failed to delete save slot $slotKey');
          }
        }
      }

      // 重置当前存档槽位
      currentSaveSlot = 'slot1';
      print('Reset current save slot to slot1');

      // 强制刷新 SharedPreferences
      await prefs.reload();
      print('Reloaded SharedPreferences');

      // 验证是否还有任何存档存在
      for (int i = 1; i <= MAX_SAVE_SLOTS; i++) {
        String slotKey = 'slot$i';
        if (prefs.containsKey(slotKey)) {
          print(
              'Error: Save slot $slotKey still exists after clearing all slots');
          throw Exception('Failed to clear all save slots');
        }
      }

      // 通知监听器更新UI
      notifyListeners();
      print('Successfully cleared all save slots and notified listeners');
    } catch (e) {
      print('Error clearing all save slots: $e');
      rethrow;
    }
  }

  // 重置游戏状态
  void resetGame() {
    // 重置基本状态
    currentLocation = 'room';
    outsideUnlocked = false;
    storeOpened = false;
    craftingUnlocked = false;

    // 重置资源
    resources = {
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

    // 重置房间状态
    room = {
      'temperature': 'cold',
      'fire': 0,
      'buildings': {},
    };

    // 重置人口信息
    population = {
      'workers': {},
      'total': 0,
      'max': 0,
      'happiness': 100,
    };

    // 重置角色状态
    character = {
      'health': 10,
      'perks': [],
    };

    // 重置世界状态
    world = {
      'explored': 0,
      'locations': {},
      'discovered_locations': [],
      'location_info': {},
    };

    // 重置建筑等级和维护信息
    buildingLevels = {};
    buildingMaintenance = {};
    buildingEfficiencyPenalty = {};

    // 重置事件和交易系统
    eventSystem.fromJson({
      'lastEventTime': DateTime.now().toIso8601String(),
      'eventHistory': [],
      'eventFlags': {},
    });
    tradeSystem.fromJson({});
    currentEvent = null;

    // 重置计时器
    eventTimer?.cancel();
    huntingTimer?.cancel();
    _waterTimer?.cancel();

    // 通知监听器更新UI
    notifyListeners();
  }
}
