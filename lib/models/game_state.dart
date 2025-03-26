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

  // 房间状态
  Map<String, dynamic> room = {
    'temperature': 'cold', // 房间温度
    'fire': 0, // 火堆状态 (0-不活跃, 1-噼啪作响, 2-燃烧, 3-咆哮)
    'buildings': {}, // 已建造的建筑
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
}
