import 'dart:math';
import 'package:flutter/foundation.dart';
import 'game_state.dart';
import 'path_system.dart';

class WorldSystem extends ChangeNotifier {
  // 日志工具方法，只在调试模式下打印
  void _log(String message) {
    if (kDebugMode) {
      print(message);
    }
  }

  // 世界常量
  static const int radius = 30;
  static const List<int> villagePos = [30, 30];

  // 地图图块定义
  static const Map<String, String> tile = {
    'VILLAGE': 'A',
    'IRON_MINE': 'I',
    'COAL_MINE': 'C',
    'SULPHUR_MINE': 'S',
    'FOREST': ';',
    'FIELD': ',',
    'BARRENS': '.',
    'ROAD': '#',
    'HOUSE': 'H',
    'CAVE': 'V',
    'TOWN': 'O',
    'CITY': 'Y',
    'OUTPOST': 'P',
    'SHIP': 'W',
    'BOREHOLE': 'B',
    'BATTLEFIELD': 'F',
    'SWAMP': 'M',
    'CACHE': 'U',
    'EXECUTIONER': 'X'
  };

  // 地块生成概率
  static const Map<String, double> tileProbs = {
    'FOREST': 0.15,
    'FIELD': 0.35,
    'BARRENS': 0.5
  };

  // 地标定义
  static final Map<String, Map<String, dynamic>> landmarks = {
    'OUTPOST': {
      'num': 0,
      'minRadius': 0,
      'maxRadius': 0,
      'scene': 'outpost',
      'label': '前哨站'
    },
    'IRON_MINE': {
      'num': 1,
      'minRadius': 5,
      'maxRadius': 5,
      'scene': 'ironmine',
      'label': '铁矿'
    },
    'COAL_MINE': {
      'num': 1,
      'minRadius': 10,
      'maxRadius': 10,
      'scene': 'coalmine',
      'label': '煤矿'
    },
    'SULPHUR_MINE': {
      'num': 1,
      'minRadius': 20,
      'maxRadius': 20,
      'scene': 'sulphurmine',
      'label': '硫磺矿'
    },
    'HOUSE': {
      'num': 10,
      'minRadius': 0,
      'maxRadius': radius * 1.5,
      'scene': 'house',
      'label': '一座老房子'
    },
    'CAVE': {
      'num': 5,
      'minRadius': 3,
      'maxRadius': 10,
      'scene': 'cave',
      'label': '潮湿的洞穴'
    },
    'TOWN': {
      'num': 10,
      'minRadius': 10,
      'maxRadius': 20,
      'scene': 'town',
      'label': '废弃的小镇'
    },
    'CITY': {
      'num': 20,
      'minRadius': 20,
      'maxRadius': radius * 1.5,
      'scene': 'city',
      'label': '被毁的城市'
    },
    'SHIP': {
      'num': 1,
      'minRadius': 28,
      'maxRadius': 28,
      'scene': 'ship',
      'label': '坠毁的星舰'
    },
    'BOREHOLE': {
      'num': 10,
      'minRadius': 15,
      'maxRadius': radius * 1.5,
      'scene': 'borehole',
      'label': '钻孔'
    },
    'BATTLEFIELD': {
      'num': 5,
      'minRadius': 18,
      'maxRadius': radius * 1.5,
      'scene': 'battlefield',
      'label': '战场'
    },
    'SWAMP': {
      'num': 1,
      'minRadius': 15,
      'maxRadius': radius * 1.5,
      'scene': 'swamp',
      'label': '浑浊的沼泽'
    },
    'EXECUTIONER': {
      'num': 1,
      'minRadius': 28,
      'maxRadius': 28,
      'scene': 'executioner',
      'label': '被摧毁的战舰'
    }
  };

  // 游戏相关常量
  static const double stickiness = 0.5; // 0 <= x <= 1
  static const int lightRadius = 5; // 增加可见范围
  static const int baseWater = 20; // 增加基础水量以便更好测试
  static const int movesPerFood = 3; // 增加移动步数，减少食物消耗
  static const int movesPerWater = 2; // 增加移动步数，减少水消耗
  static const int deathCooldown = 120;
  static const double fightChance = 0.20;
  static const int baseHealth = 10;
  static const double baseHitChance = 0.8;
  static const int meatHeal = 8;
  static const int medsHeal = 20;
  static const int hypoHeal = 30;
  static const int fightDelay = 3; // 战斗之间至少三步

  // 方向定义
  static const List<int> north = [0, -1];
  static const List<int> south = [0, 1];
  static const List<int> west = [-1, 0];
  static const List<int> east = [1, 0];

  // 武器定义
  static const Map<String, Map<String, dynamic>> weapons = {
    'fists': {'verb': '拳击', 'type': 'unarmed', 'damage': 1, 'cooldown': 2},
    'bone spear': {'verb': '刺击', 'type': 'melee', 'damage': 2, 'cooldown': 2},
    'iron sword': {'verb': '挥砍', 'type': 'melee', 'damage': 4, 'cooldown': 2},
    'steel sword': {'verb': '劈砍', 'type': 'melee', 'damage': 6, 'cooldown': 2},
    'bayonet': {'verb': '刺刺', 'type': 'melee', 'damage': 8, 'cooldown': 2},
    'rifle': {
      'verb': '射击',
      'type': 'ranged',
      'damage': 5,
      'cooldown': 1,
      'cost': {'bullets': 1}
    },
    'laser rifle': {
      'verb': '爆破',
      'type': 'ranged',
      'damage': 8,
      'cooldown': 1,
      'cost': {'energy cell': 1}
    },
    'grenade': {
      'verb': '投掷',
      'type': 'ranged',
      'damage': 15,
      'cooldown': 5,
      'cost': {'grenade': 1}
    },
    'bolas': {
      'verb': '缠绕',
      'type': 'ranged',
      'damage': 'stun',
      'cooldown': 15,
      'cost': {'bolas': 1}
    },
    'plasma rifle': {
      'verb': '分解',
      'type': 'ranged',
      'damage': 12,
      'cooldown': 1,
      'cost': {'energy cell': 1}
    },
    'energy blade': {
      'verb': '劈切',
      'type': 'melee',
      'damage': 10,
      'cooldown': 2
    },
    'disruptor': {
      'verb': '击晕',
      'type': 'ranged',
      'damage': 'stun',
      'cooldown': 15
    }
  };

  // 地图数据
  List<List<String>> map = [];
  List<List<bool>> mask = [];
  List<List<int>> landmarkObjects = [];

  // 玩家位置
  List<int> position = [villagePos[0], villagePos[1]];
  List<int> lastPosition = [villagePos[0], villagePos[1]];

  // 资源和状态
  int water = baseWater;
  int moves = 0;
  int food = 0;
  int totalMoveCount = 0;
  bool fightAvailable = false;
  int fightTimer = 0;
  bool isDead = false;
  int deathTimer = deathCooldown;

  // 特殊位置
  List<int>? shipLocation;

  // 初始化世界
  void init() {
    if (kDebugMode) {
      _log('开始初始化世界地图系统');
    }

    try {
      if (map.isEmpty) {
        if (kDebugMode) {
          _log('地图为空，开始生成地图');
        }
        generateMap();
      } else {
        if (kDebugMode) {
          _log('地图已存在，大小: ${map.length}x${map[0].length}');
        }
      }

      // 确保玩家位置正确设置
      if (position.isEmpty) {
        position = [villagePos[0], villagePos[1]];
        lastPosition = List.from(position); // 初始化上一个位置
        if (kDebugMode) {
          _log('玩家位置未设置，设置默认位置：$position');
        }
      } else {
        if (kDebugMode) {
          _log('玩家当前位置：$position');
        }
      }

      // 确保lastPosition已初始化
      if (lastPosition.isEmpty) {
        lastPosition = List.from(position);
        if (kDebugMode) {
          _log('上一个位置未设置，设置为当前位置：$lastPosition');
        }
      }

      // 确保可见性掩码已初始化
      if (mask.isEmpty) {
        updateMask();
        if (kDebugMode) {
          _log('重新生成可见性掩码');
        }
      }

      // 确保水资源已初始化
      if (water <= 0) {
        water = baseWater;
        if (kDebugMode) {
          _log('重置水资源为默认值: $water');
        }
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        _log('世界地图初始化出错: $e');
      }
      // 尝试恢复到初始状态
      resetWorld();
    }
  }

  // 重置世界到初始状态
  void resetWorld() {
    map = [];
    mask = [];
    position = [villagePos[0], villagePos[1]];
    lastPosition = List.from(position);
    landmarkObjects = [];
    water = baseWater;
    moves = 0;
    food = 0;
    generateMap();
    notifyListeners();
  }

  // 生成世界地图
  void generateMap() {
    Random random = Random();

    // 创建空白地图
    map = List.generate(
        radius * 2, (_) => List.generate(radius * 2, (_) => tile['BARRENS']!));

    // 创建遮罩
    mask = List.generate(
        radius * 2, (_) => List.generate(radius * 2, (_) => false));

    // 生成地形
    for (int y = 0; y < radius * 2; y++) {
      for (int x = 0; x < radius * 2; x++) {
        if (x == villagePos[0] && y == villagePos[1]) {
          map[y][x] = tile['VILLAGE']!;
        } else {
          double r = random.nextDouble();
          if (r < tileProbs['FOREST']!) {
            map[y][x] = tile['FOREST']!;
          } else if (r < tileProbs['FOREST']! + tileProbs['FIELD']!) {
            map[y][x] = tile['FIELD']!;
          } else {
            map[y][x] = tile['BARRENS']!;
          }
        }
      }
    }

    // 放置地标
    landmarks.forEach((key, landmark) {
      for (int i = 0; i < landmark['num']; i++) {
        placeLandmark(landmark['minRadius'], landmark['maxRadius'], tile[key]!);
      }
    });

    // 找到飞船位置
    shipLocation = findLocationOnMap(tile['SHIP']!);
  }

  // 放置地标
  void placeLandmark(int minRadius, int maxRadius, String tileType) {
    Random random = Random();
    int x, y;
    double r;
    bool validLocation = false;

    // 尝试放置地标
    while (!validLocation) {
      r = minRadius + random.nextDouble() * (maxRadius - minRadius);
      double angle = random.nextDouble() * 2 * pi;

      x = (villagePos[0] + r * cos(angle)).round();
      y = (villagePos[1] + r * sin(angle)).round();

      if (x >= 0 && x < radius * 2 && y >= 0 && y < radius * 2) {
        if (map[y][x] != tile['VILLAGE'] &&
            map[y][x] != tile['IRON_MINE'] &&
            map[y][x] != tile['COAL_MINE'] &&
            map[y][x] != tile['SULPHUR_MINE']) {
          map[y][x] = tileType;
          validLocation = true;
        }
      }
    }
  }

  // 查找地图上的位置
  List<int>? findLocationOnMap(String tile) {
    for (int y = 0; y < map.length; y++) {
      for (int x = 0; x < map[y].length; x++) {
        if (map[y][x] == tile) {
          return [x, y];
        }
      }
    }
    return null;
  }

  // 更新可见性遮罩
  void updateMask() {
    int x = position[0];
    int y = position[1];

    // 更新可见范围
    for (int i = -lightRadius; i <= lightRadius; i++) {
      for (int j = -lightRadius; j <= lightRadius; j++) {
        if (x + i >= 0 &&
            x + i < radius * 2 &&
            y + j >= 0 &&
            y + j < radius * 2) {
          if (sqrt(i * i + j * j) <= lightRadius) {
            mask[y + j][x + i] = true;
          }
        }
      }
    }
  }

  /// 移动，根据方向移动位置
  bool move(String direction, PathSystem pathSystem, GameState gameState) {
    if (kDebugMode) {
      _log('移动尝试: 方向=$direction, 当前位置=$position, 水量=$water');
      _log('背包内容: ${pathSystem.outfit}');
    }

    // 检查水和食物
    if (water <= 0) {
      if (kDebugMode) {
        _log('移动失败: 水不足');
      }
      return false;
    }

    if (!pathSystem.hasFood()) {
      if (kDebugMode) {
        _log('移动失败: 食物不足');
      }
      return false;
    }

    // 计算新位置
    List<int> newPos;
    switch (direction) {
      case 'north':
        newPos = [position[0], position[1] - 1];
        break;
      case 'south':
        newPos = [position[0], position[1] + 1];
        break;
      case 'west':
        newPos = [position[0] - 1, position[1]];
        break;
      case 'east':
        newPos = [position[0] + 1, position[1]];
        break;
      default:
        if (kDebugMode) {
          _log('移动失败: 无效方向');
        }
        return false;
    }

    // 边界检查
    if (newPos[0] < 0 ||
        newPos[0] >= radius * 2 ||
        newPos[1] < 0 ||
        newPos[1] >= radius * 2) {
      if (kDebugMode) {
        _log('移动失败: 边界检查失败 - 新位置($newPos)超出地图边界');
      }
      return false;
    }

    // 水消耗
    water = (water - 1 < 0) ? 0 : water - 1;

    // 移动计数和食物消耗
    moves++;
    totalMoveCount++; // 增加总移动计数
    if (moves >= movesPerFood) {
      if (!pathSystem.consumeFood()) {
        if (kDebugMode) {
          _log('移动失败: 食物消耗失败');
        }
        return false;
      }
      moves = 0;
    }

    // 保存上一个位置用于检测
    lastPosition = List.from(position);

    // 更新位置
    position = newPos;

    // 更新可见范围
    updateMask();

    String currentTile = map[position[1]][position[0]];
    String lastTile = map[lastPosition[1]][lastPosition[0]];

    if (kDebugMode) {
      _log(
          '移动成功: 新位置=$position ($currentTile), 上一位置=$lastPosition ($lastTile)');
      _log('剩余水量=$water, 移动步数=$moves, 总移动次数=$totalMoveCount');
      _log('游戏当前状态=${gameState.currentLocation}');
    }

    // 检查地点事件
    checkLocationEvents(gameState);

    notifyListeners();
    return true;
  }

  // 检查当前位置的地点
  void checkLocationEvents(GameState gameState) {
    // 用于总移动次数追踪
    if (kDebugMode) {
      _log('=== 检查位置事件 ===');
      _log('当前位置: $position, 地块类型: ${map[position[1]][position[0]]}');
      _log(
          '上一位置: $lastPosition, 地块类型: ${lastPosition.isNotEmpty ? map[lastPosition[1]][lastPosition[0]] : ''}');
      _log('游戏当前状态: ${gameState.currentLocation}');
      _log('已移动步数: $moves, 水量: $water');

      // 添加简单的步数计数，用于调试多次移动的问题
      totalMoveCount++;
      _log('总移动次数: $totalMoveCount');
    }

    // 检查是否刚进入村庄
    if (position.isEmpty || lastPosition.isEmpty) return;

    String currentTile = map[position[1]][position[0]];
    String lastTile =
        lastPosition.isNotEmpty ? map[lastPosition[1]][lastPosition[0]] : '';

    if (currentTile == tile['VILLAGE']) {
      // 只有当从外部回到村庄时才切换回房间
      // 如果上一个位置不是村庄，则触发返回房间
      if (lastTile != tile['VILLAGE'] && lastTile.isNotEmpty) {
        if (kDebugMode) {
          _log('从外部进入村庄，返回房间');
        }
        // 延迟切换位置，避免状态更新冲突
        Future.delayed(Duration.zero, () {
          if (gameState.currentLocation == 'world') {
            gameState.currentLocation = 'room';
            gameState.notifyListeners();
          }
        });
      } else {
        if (kDebugMode) {
          _log('在村庄内移动，不返回房间');
        }
      }
    } else if (currentTile == tile['IRON_MINE']) {
      // 处理铁矿事件
      gameState.currentLocation = 'ironMine';
    } else if (currentTile == tile['COAL_MINE']) {
      // 处理煤矿事件
      gameState.currentLocation = 'coalMine';
    } else if (currentTile == tile['FOREST']) {
      // 处理森林事件
      gameState.currentLocation = 'forest';
    } else if (currentTile == tile['SULPHUR_MINE']) {
      // 处理硫磺矿事件
      gameState.currentLocation = 'sulphurMine';
    } else if (currentTile == tile['HOUSE']) {
      // 处理房子事件
      gameState.currentLocation = 'house';
    } else if (currentTile == tile['CAVE']) {
      // 处理洞穴事件
      gameState.currentLocation = 'cave';
    } else if (currentTile == tile['TOWN']) {
      // 处理小镇事件
      gameState.currentLocation = 'town';
    } else if (currentTile == tile['CITY']) {
      // 处理城市事件
      gameState.currentLocation = 'city';
    } else if (currentTile == tile['OUTPOST']) {
      // 处理前哨站事件
      gameState.currentLocation = 'outpost';
    } else if (currentTile == tile['SHIP']) {
      // 处理星舰事件
      gameState.currentLocation = 'ship';
    } else if (currentTile == tile['BOREHOLE']) {
      // 处理钻孔事件
      gameState.currentLocation = 'borehole';
    } else if (currentTile == tile['BATTLEFIELD']) {
      // 处理战场事件
      gameState.currentLocation = 'battlefield';
    } else if (currentTile == tile['SWAMP']) {
      // 处理沼泽事件
      gameState.currentLocation = 'swamp';
    } else if (currentTile == tile['EXECUTIONER']) {
      // 处理被摧毁的战舰事件
      gameState.currentLocation = 'executioner';
    }

    // 处理遇到的地点
    // 查找与当前地块匹配的地标
    String? landmarkKey;
    for (var entry in landmarks.entries) {
      if (tile[entry.key] == currentTile) {
        landmarkKey = entry.key;
        break;
      }
    }

    if (landmarkKey != null) {
      // 标记为发现
      if (!gameState.world['discovered_locations'].contains(landmarkKey)) {
        gameState.world['discovered_locations'].add(landmarkKey);
      }

      // 保存位置信息
      var landmark = landmarks[landmarkKey]!;
      gameState.world['location_info'][landmarkKey] = {
        'x': position[0],
        'y': position[1],
        'label': landmark['label'],
        'scene': landmark['scene'],
      };
    }

    // 随机战斗检查
    if (fightTimer <= 0 && Random().nextDouble() < fightChance) {
      // 触发战斗
      // 这里简单标记，实际实现需要连接到战斗系统
      fightTimer = fightDelay;
    }

    // 更新状态
    notifyListeners();
  }

  // 获取指南针方向
  String getCompassDirection() {
    if (shipLocation == null) return '未知';

    double angle =
        atan2(shipLocation![1] - position[1], shipLocation![0] - position[0]);

    angle = angle * 180 / pi;

    if (angle < -157.5) return '西';
    if (angle < -112.5) return '西北';
    if (angle < -67.5) return '北';
    if (angle < -22.5) return '东北';
    if (angle < 22.5) return '东';
    if (angle < 67.5) return '东南';
    if (angle < 112.5) return '南';
    if (angle < 157.5) return '西南';
    return '西';
  }

  // 从JSON加载
  void fromJson(Map<String, dynamic> json) {
    // 加载地图
    if (json['map'] != null) {
      List<dynamic> mapData = json['map'];
      map = mapData.map((row) => List<String>.from(row)).toList();
    }

    // 加载遮罩
    if (json['mask'] != null) {
      List<dynamic> maskData = json['mask'];
      mask = maskData.map((row) => List<bool>.from(row)).toList();
    }

    // 加载位置
    if (json['position'] != null) {
      List<dynamic> pos = json['position'];
      position = [pos[0], pos[1]];
    } else {
      position = [villagePos[0], villagePos[1]];
    }

    // 加载上一个位置
    if (json['lastPosition'] != null) {
      List<dynamic> lastPos = json['lastPosition'];
      lastPosition = [lastPos[0], lastPos[1]];
    } else {
      // 如果没有保存上一个位置，使用当前位置
      lastPosition = List.from(position);
    }

    // 加载飞船位置
    if (json['shipLocation'] != null) {
      List<dynamic> ship = json['shipLocation'];
      shipLocation = [ship[0], ship[1]];
    } else {
      shipLocation = findLocationOnMap(tile['SHIP']!);
    }

    // 加载资源
    water = json['water'] ?? baseWater;
    food = json['food'] ?? 0;
    moves = json['moves'] ?? 0;

    // 加载战斗冷却
    fightTimer = json['fightTimer'] ?? 0;
  }

  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'map': map,
      'mask': mask,
      'position': position,
      'lastPosition': lastPosition,
      'shipLocation': shipLocation,
      'water': water,
      'food': food,
      'moves': moves,
      'fightTimer': fightTimer,
    };
  }
}
