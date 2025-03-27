import 'dart:math';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'game_state.dart';
import 'path_system.dart';

class WorldSystem extends ChangeNotifier {
  // 世界常量
  static const int RADIUS = 30;
  static const List<int> VILLAGE_POS = [30, 30];

  // 地图图块定义
  static const Map<String, String> TILE = {
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
  static const Map<String, double> TILE_PROBS = {
    'FOREST': 0.15,
    'FIELD': 0.35,
    'BARRENS': 0.5
  };

  // 地标定义
  static final Map<String, Map<String, dynamic>> LANDMARKS = {
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
      'maxRadius': RADIUS * 1.5,
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
      'maxRadius': RADIUS * 1.5,
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
      'maxRadius': RADIUS * 1.5,
      'scene': 'borehole',
      'label': '钻孔'
    },
    'BATTLEFIELD': {
      'num': 5,
      'minRadius': 18,
      'maxRadius': RADIUS * 1.5,
      'scene': 'battlefield',
      'label': '战场'
    },
    'SWAMP': {
      'num': 1,
      'minRadius': 15,
      'maxRadius': RADIUS * 1.5,
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
  static const double STICKINESS = 0.5; // 0 <= x <= 1
  static const int LIGHT_RADIUS = 5; // 增加可见范围
  static const int BASE_WATER = 20; // 增加基础水量以便更好测试
  static const int MOVES_PER_FOOD = 3; // 增加移动步数，减少食物消耗
  static const int MOVES_PER_WATER = 2; // 增加移动步数，减少水消耗
  static const int DEATH_COOLDOWN = 120;
  static const double FIGHT_CHANCE = 0.20;
  static const int BASE_HEALTH = 10;
  static const double BASE_HIT_CHANCE = 0.8;
  static const int MEAT_HEAL = 8;
  static const int MEDS_HEAL = 20;
  static const int HYPO_HEAL = 30;
  static const int FIGHT_DELAY = 3; // 战斗之间至少三步

  // 方向定义
  static const List<int> NORTH = [0, -1];
  static const List<int> SOUTH = [0, 1];
  static const List<int> WEST = [-1, 0];
  static const List<int> EAST = [1, 0];

  // 武器定义
  static const Map<String, Map<String, dynamic>> WEAPONS = {
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

  // 世界数据与位置
  List<List<String>> map = [];
  List<List<bool>> mask = []; // 可见性掩码
  List<int>? position;
  List<int>? lastPosition; // 记录上一个位置，用于检测从哪里进入当前位置
  List<List<String>> landmarks = [];
  int water = BASE_WATER;

  // 飞船位置
  List<int>? shipLocation;

  // 资源计数
  int food = 0;
  int moves = 0;
  int totalMoveCount = 0; // 总移动次数，用于调试

  // 战斗相关
  int fightCooldown = 0;

  // 初始化世界
  void init() {
    if (kDebugMode) {
      print('开始初始化世界地图系统');
    }

    try {
      if (map.isEmpty) {
        if (kDebugMode) {
          print('地图为空，开始生成地图');
        }
        generateMap();
      } else {
        if (kDebugMode) {
          print('地图已存在，大小: ${map.length}x${map[0].length}');
        }
      }

      // 确保玩家位置正确设置
      if (position == null) {
        position = [VILLAGE_POS[0], VILLAGE_POS[1]];
        lastPosition = List.from(position!); // 初始化上一个位置
        if (kDebugMode) {
          print('玩家位置未设置，设置默认位置：$position');
        }
      } else {
        if (kDebugMode) {
          print('玩家当前位置：$position');
        }
      }

      // 确保lastPosition已初始化
      if (lastPosition == null) {
        lastPosition = List.from(position!);
        if (kDebugMode) {
          print('上一个位置未设置，设置为当前位置：$lastPosition');
        }
      }

      // 确保可见性掩码已初始化
      if (mask.isEmpty) {
        updateMask();
        if (kDebugMode) {
          print('重新生成可见性掩码');
        }
      }

      // 确保水资源已初始化
      if (water <= 0) {
        water = BASE_WATER;
        if (kDebugMode) {
          print('重置水资源为默认值: $water');
        }
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('世界地图初始化出错: $e');
      }
      // 尝试恢复到初始状态
      resetWorld();
    }
  }

  // 重置世界到初始状态
  void resetWorld() {
    map = [];
    mask = [];
    position = [VILLAGE_POS[0], VILLAGE_POS[1]];
    lastPosition = List.from(position!);
    landmarks = [];
    water = BASE_WATER;
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
        RADIUS * 2, (_) => List.generate(RADIUS * 2, (_) => TILE['BARRENS']!));

    // 创建遮罩
    mask = List.generate(
        RADIUS * 2, (_) => List.generate(RADIUS * 2, (_) => false));

    // 生成地形
    for (int y = 0; y < RADIUS * 2; y++) {
      for (int x = 0; x < RADIUS * 2; x++) {
        if (x == VILLAGE_POS[0] && y == VILLAGE_POS[1]) {
          map[y][x] = TILE['VILLAGE']!;
        } else {
          double r = random.nextDouble();
          if (r < TILE_PROBS['FOREST']!) {
            map[y][x] = TILE['FOREST']!;
          } else if (r < TILE_PROBS['FOREST']! + TILE_PROBS['FIELD']!) {
            map[y][x] = TILE['FIELD']!;
          } else {
            map[y][x] = TILE['BARRENS']!;
          }
        }
      }
    }

    // 放置地标
    LANDMARKS.forEach((key, landmark) {
      for (int i = 0; i < landmark['num']; i++) {
        placeLandmark(landmark['minRadius'], landmark['maxRadius'], TILE[key]!);
      }
    });

    // 找到飞船位置
    shipLocation = findLocationOnMap(TILE['SHIP']!);
  }

  // 放置地标
  void placeLandmark(int minRadius, int maxRadius, String tile) {
    Random random = Random();
    int x, y;
    double r;
    bool validLocation = false;

    // 尝试放置地标
    while (!validLocation) {
      r = minRadius + random.nextDouble() * (maxRadius - minRadius);
      double angle = random.nextDouble() * 2 * pi;

      x = (VILLAGE_POS[0] + r * cos(angle)).round();
      y = (VILLAGE_POS[1] + r * sin(angle)).round();

      if (x >= 0 && x < RADIUS * 2 && y >= 0 && y < RADIUS * 2) {
        if (map[y][x] != TILE['VILLAGE'] &&
            map[y][x] != TILE['IRON_MINE'] &&
            map[y][x] != TILE['COAL_MINE'] &&
            map[y][x] != TILE['SULPHUR_MINE']) {
          map[y][x] = tile;
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
    int x = position![0];
    int y = position![1];

    // 更新可见范围
    for (int i = -LIGHT_RADIUS; i <= LIGHT_RADIUS; i++) {
      for (int j = -LIGHT_RADIUS; j <= LIGHT_RADIUS; j++) {
        if (x + i >= 0 &&
            x + i < RADIUS * 2 &&
            y + j >= 0 &&
            y + j < RADIUS * 2) {
          if (sqrt(i * i + j * j) <= LIGHT_RADIUS) {
            mask[y + j][x + i] = true;
          }
        }
      }
    }
  }

  /// 移动，根据方向移动位置
  bool move(String direction, PathSystem pathSystem, GameState gameState) {
    if (kDebugMode) {
      print('移动尝试: 方向=$direction, 当前位置=$position, 水量=$water');
      print('背包内容: ${pathSystem.outfit}');
    }

    // 检查水和食物
    if (water <= 0) {
      if (kDebugMode) {
        print('移动失败: 水不足');
      }
      return false;
    }

    if (!pathSystem.hasFood()) {
      if (kDebugMode) {
        print('移动失败: 食物不足');
      }
      return false;
    }

    // 计算新位置
    List<int> newPos;
    switch (direction) {
      case 'north':
        newPos = [position![0], position![1] - 1];
        break;
      case 'south':
        newPos = [position![0], position![1] + 1];
        break;
      case 'west':
        newPos = [position![0] - 1, position![1]];
        break;
      case 'east':
        newPos = [position![0] + 1, position![1]];
        break;
      default:
        if (kDebugMode) {
          print('移动失败: 无效方向');
        }
        return false;
    }

    // 边界检查
    if (newPos[0] < 0 ||
        newPos[0] >= RADIUS * 2 ||
        newPos[1] < 0 ||
        newPos[1] >= RADIUS * 2) {
      if (kDebugMode) {
        print('移动失败: 边界检查失败 - 新位置($newPos)超出地图边界');
      }
      return false;
    }

    // 水消耗
    water = (water - 1 < 0) ? 0 : water - 1;

    // 移动计数和食物消耗
    moves++;
    totalMoveCount++; // 增加总移动计数
    if (moves >= MOVES_PER_FOOD) {
      if (!pathSystem.consumeFood()) {
        if (kDebugMode) {
          print('移动失败: 食物消耗失败');
        }
        return false;
      }
      moves = 0;
    }

    // 保存上一个位置用于检测
    lastPosition = List.from(position!);

    // 更新位置
    position = newPos;

    // 更新可见范围
    updateMask();

    String currentTile = map[position![1]][position![0]];
    String lastTile = map[lastPosition![1]][lastPosition![0]];

    if (kDebugMode) {
      print(
          '移动成功: 新位置=$position ($currentTile), 上一位置=$lastPosition ($lastTile)');
      print('剩余水量=$water, 移动步数=$moves, 总移动次数=$totalMoveCount');
      print('游戏当前状态=${gameState.currentLocation}');
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
      print('=== 检查位置事件 ===');
      print('当前位置: $position, 地块类型: ${map[position![1]][position![0]]}');
      print(
          '上一位置: $lastPosition, 地块类型: ${lastPosition != null ? map[lastPosition![1]][lastPosition![0]] : ''}');
      print('游戏当前状态: ${gameState.currentLocation}');
      print('已移动步数: $moves, 水量: $water');

      // 添加简单的步数计数，用于调试多次移动的问题
      totalMoveCount++;
      print('总移动次数: $totalMoveCount');
    }

    // 检查是否刚进入村庄
    if (position == null || lastPosition == null) return;

    String currentTile = map[position![1]][position![0]];
    String lastTile =
        lastPosition != null ? map[lastPosition![1]][lastPosition![0]] : '';

    if (currentTile == TILE['VILLAGE']) {
      // 只有当从外部回到村庄时才切换回房间
      // 如果上一个位置不是村庄，则触发返回房间
      if (lastTile != TILE['VILLAGE'] && lastTile.isNotEmpty) {
        if (kDebugMode) {
          print('从外部进入村庄，返回房间');
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
          print('在村庄内移动，不返回房间');
        }
      }
    } else if (currentTile == TILE['IRON_MINE']) {
      // 处理铁矿事件
      gameState.currentLocation = 'ironMine';
    } else if (currentTile == TILE['COAL_MINE']) {
      // 处理煤矿事件
      gameState.currentLocation = 'coalMine';
    } else if (currentTile == TILE['FOREST']) {
      // 处理森林事件
      gameState.currentLocation = 'forest';
    } else if (currentTile == TILE['SULPHUR_MINE']) {
      // 处理硫磺矿事件
      gameState.currentLocation = 'sulphurMine';
    } else if (currentTile == TILE['HOUSE']) {
      // 处理房子事件
      gameState.currentLocation = 'house';
    } else if (currentTile == TILE['CAVE']) {
      // 处理洞穴事件
      gameState.currentLocation = 'cave';
    } else if (currentTile == TILE['TOWN']) {
      // 处理小镇事件
      gameState.currentLocation = 'town';
    } else if (currentTile == TILE['CITY']) {
      // 处理城市事件
      gameState.currentLocation = 'city';
    } else if (currentTile == TILE['OUTPOST']) {
      // 处理前哨站事件
      gameState.currentLocation = 'outpost';
    } else if (currentTile == TILE['SHIP']) {
      // 处理星舰事件
      gameState.currentLocation = 'ship';
    } else if (currentTile == TILE['BOREHOLE']) {
      // 处理钻孔事件
      gameState.currentLocation = 'borehole';
    } else if (currentTile == TILE['BATTLEFIELD']) {
      // 处理战场事件
      gameState.currentLocation = 'battlefield';
    } else if (currentTile == TILE['SWAMP']) {
      // 处理沼泽事件
      gameState.currentLocation = 'swamp';
    } else if (currentTile == TILE['EXECUTIONER']) {
      // 处理被摧毁的战舰事件
      gameState.currentLocation = 'executioner';
    }

    // 处理遇到的地点
    if (LANDMARKS.entries.any((entry) => TILE[entry.key] == currentTile)) {
      // 找到对应地标
      var landmark = LANDMARKS.entries.firstWhere(
        (entry) => TILE[entry.key] == currentTile,
        orElse: () => MapEntry('BARRENS', LANDMARKS['BARRENS']!),
      );

      // 标记为发现
      if (!gameState.world['discovered_locations'].contains(landmark.key)) {
        gameState.world['discovered_locations'].add(landmark.key);
      }

      // 保存位置信息
      gameState.world['location_info'][landmark.key] = {
        'x': position![0],
        'y': position![1],
        'label': landmark.value['label'],
        'scene': landmark.value['scene'],
      };
    }

    // 随机战斗检查
    if (fightCooldown <= 0 && Random().nextDouble() < FIGHT_CHANCE) {
      // 触发战斗
      // 这里简单标记，实际实现需要连接到战斗系统
      fightCooldown = FIGHT_DELAY;
    }

    // 更新状态
    notifyListeners();
  }

  // 获取指南针方向
  String getCompassDirection() {
    if (shipLocation == null) return '未知';

    double angle =
        atan2(shipLocation![1] - position![1], shipLocation![0] - position![0]);

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
      position = [VILLAGE_POS[0], VILLAGE_POS[1]];
    }

    // 加载上一个位置
    if (json['lastPosition'] != null) {
      List<dynamic> lastPos = json['lastPosition'];
      lastPosition = [lastPos[0], lastPos[1]];
    } else {
      // 如果没有保存上一个位置，使用当前位置
      lastPosition = List.from(position!);
    }

    // 加载飞船位置
    if (json['shipLocation'] != null) {
      List<dynamic> ship = json['shipLocation'];
      shipLocation = [ship[0], ship[1]];
    } else {
      shipLocation = findLocationOnMap(TILE['SHIP']!);
    }

    // 加载资源
    water = json['water'] ?? BASE_WATER;
    food = json['food'] ?? 0;
    moves = json['moves'] ?? 0;

    // 加载战斗冷却
    fightCooldown = json['fightCooldown'] ?? 0;
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
      'fightCooldown': fightCooldown,
    };
  }
}
