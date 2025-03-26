/// 游戏状态类 - 负责存储游戏中的所有状态数据
class GameState {
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

  // 建筑定义
  final Map<String, Map<String, dynamic>> availableBuildings = {
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
    'lodge': {
      'name': '狩猎营地',
      'description': '让狩猎者更有效率。',
      'cost': {'wood': 200, 'fur': 10, 'meat': 5},
      'notification': '建造了狩猎营地，狩猎效率提升。'
    },
    'trading post': {
      'name': '贸易站',
      'description': '吸引商人。',
      'cost': {'wood': 400, 'fur': 100},
      'notification': '建造了贸易站，会有商人来访。'
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

  GameState();

  // 从JSON创建游戏状态
  GameState.fromJson(Map<String, dynamic> json) {
    currentLocation = json['currentLocation'] ?? 'room';
    resources = Map<String, int>.from(json['resources'] ?? {});
    room = Map<String, dynamic>.from(json['room'] ?? {});
    character = Map<String, dynamic>.from(json['character'] ?? {});
    world = Map<String, dynamic>.from(json['world'] ?? {});
    population = Map<String, dynamic>.from(
        json['population'] ?? {'workers': {}, 'total': 0});
    storeOpened = json['storeOpened'] ?? false;
    outsideUnlocked = json['outsideUnlocked'] ?? false;
    craftingUnlocked = json['craftingUnlocked'] ?? false;
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
    };
  }

  // 添加资源
  void addResource(String name, int amount) {
    if (resources.containsKey(name)) {
      resources[name] = (resources[name] ?? 0) + amount;
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

    // 检查已建造的数量
    int builtCount = room['buildings'][buildingId] ?? 0;

    // 检查资源是否足够
    Map<String, dynamic> cost =
        availableBuildings[buildingId]!['cost'] as Map<String, dynamic>;
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
    if (!canBuild(buildingId)) {
      return false;
    }

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
    if (buildingId == 'trading post' &&
        (room['buildings'][buildingId] ?? 0) == 1) {
      storeOpened = true;
    }

    return true;
  }

  // 获取建筑数量
  int getBuildingCount(String buildingId) {
    if (room['buildings'] is! Map) {
      return 0;
    }
    return room['buildings'][buildingId] ?? 0;
  }
}
