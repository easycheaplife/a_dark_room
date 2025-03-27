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
  static const int LIGHT_RADIUS = 2;
  static const int BASE_WATER = 10;
  static const int MOVES_PER_FOOD = 2;
  static const int MOVES_PER_WATER = 1;
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

  // 世界地图
  List<List<String>> map = [];

  // 地图可见性遮罩
  List<List<bool>> mask = [];

  // 当前位置
  List<int> position = [VILLAGE_POS[0], VILLAGE_POS[1]];

  // 飞船位置
  List<int>? shipLocation;

  // 资源计数
  int water = BASE_WATER;
  int food = 0;
  int moves = 0;

  // 战斗相关
  int fightCooldown = 0;

  // 初始化世界地图
  void init() {
    Random random = Random();

    // 生成新地图
    generateMap();

    // 初始化水和食物
    water = BASE_WATER;
    food = 0;

    // 初始位置为村庄
    position = [VILLAGE_POS[0], VILLAGE_POS[1]];

    // 更新可见范围
    updateMask();

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
    int x = position[0];
    int y = position[1];

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

  // 移动到指定方向
  bool move(List<int> direction, GameState gameState, PathSystem pathSystem) {
    // 检查水和食物
    if (water <= 0 ||
        pathSystem.outfit['cured meat'] == null ||
        pathSystem.outfit['cured meat']! <= 0) {
      return false;
    }

    // 计算新位置
    int newX = position[0] + direction[0];
    int newY = position[1] + direction[1];

    // 检查边界
    if (newX < 0 || newX >= RADIUS * 2 || newY < 0 || newY >= RADIUS * 2) {
      return false;
    }

    // 更新位置
    position = [newX, newY];

    // 消耗水
    moves++;
    if (moves >= MOVES_PER_WATER) {
      water--;
      moves = 0;
    }

    // 消耗食物
    int foodInterval = 0;
    foodInterval++;
    if (foodInterval >= MOVES_PER_FOOD) {
      pathSystem.outfit['cured meat'] = pathSystem.outfit['cured meat']! - 1;
      foodInterval = 0;
    }

    // 更新可见范围
    updateMask();

    // 处理战斗冷却
    if (fightCooldown > 0) {
      fightCooldown--;
    }

    // 检查遇到的地点
    checkLocation(gameState);

    notifyListeners();
    return true;
  }

  // 检查当前位置的地点
  void checkLocation(GameState gameState) {
    String currentTile = map[position[1]][position[0]];

    // 如果是村庄，就回到村子
    if (currentTile == TILE['VILLAGE']) {
      gameState.currentLocation = 'room';
      return;
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
        'x': position[0],
        'y': position[1],
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
      position = [VILLAGE_POS[0], VILLAGE_POS[1]];
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
      'shipLocation': shipLocation,
      'water': water,
      'food': food,
      'moves': moves,
      'fightCooldown': fightCooldown,
    };
  }
}
