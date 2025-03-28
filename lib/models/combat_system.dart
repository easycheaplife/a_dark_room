import 'dart:math';
import 'game_state.dart';
import '../config/game_settings.dart';

class Equipment {
  final String id;
  final String name;
  final String type; // weapon, armor
  final int attack;
  final int defense;
  final Map<String, dynamic>? effects;

  Equipment({
    required this.id,
    required this.name,
    required this.type,
    this.attack = 0,
    this.defense = 0,
    this.effects,
  });
}

class Enemy {
  final String id;
  final String name;
  final String description;
  final int health;
  final int attack;
  final int defense;
  final Map<String, int> loot;
  final int experienceReward;

  Enemy({
    required this.id,
    required this.name,
    required this.description,
    required this.health,
    required this.attack,
    required this.defense,
    required this.loot,
    required this.experienceReward,
  });
}

class CombatSystem {
  final Random _random = Random();

  // 装备数据
  final Map<String, Equipment> equipment = {
    'sword': Equipment(
      id: 'sword',
      name: '剑',
      type: 'weapon',
      attack: 5,
      defense: 1,
    ),
    'gun': Equipment(
      id: 'gun',
      name: '枪',
      type: 'weapon',
      attack: 8,
      defense: 0,
      effects: {
        'requires': 'bullet',
        'ammo_per_shot': 1,
      },
    ),
    'armor': Equipment(
      id: 'armor',
      name: '盔甲',
      type: 'armor',
      attack: 0,
      defense: 5,
    ),
  };

  // 敌人数据
  final Map<String, Enemy> enemies = {
    'wolf': Enemy(
      id: 'wolf',
      name: '狼',
      description: '一只饥饿的狼',
      health: 30,
      attack: 4,
      defense: 2,
      loot: {
        'fur': 2,
        'meat': 1,
        'teeth': 1,
      },
      experienceReward: 10,
    ),
    'bear': Enemy(
      id: 'bear',
      name: '熊',
      description: '一只凶猛的熊',
      health: 50,
      attack: 6,
      defense: 3,
      loot: {
        'fur': 3,
        'meat': 2,
        'teeth': 2,
      },
      experienceReward: 20,
    ),
    'bandit': Enemy(
      id: 'bandit',
      name: '强盗',
      description: '一个危险的强盗',
      health: 40,
      attack: 5,
      defense: 4,
      loot: {
        'cloth': 1,
        'leather': 1,
        'money': 10,
      },
      experienceReward: 15,
    ),
  };

  // 当前战斗状态
  Map<String, dynamic> _combatState =
      Map<String, dynamic>.from(GameSettings.initialCombatState);

  // 获取当前装备的攻击力和防御力
  Map<String, int> getEquipmentStats(GameState state) {
    int totalAttack = 3; // 提高基础攻击力
    int totalDefense = 1; // 提供基础防御力

    // 根据玩家等级增加属性
    int level = state.level;
    totalAttack += level;
    totalDefense += (level / 2).floor();

    // 检查装备
    if (state.resources.containsKey('sword') && state.resources['sword']! > 0) {
      totalAttack += equipment['sword']!.attack;
      totalDefense += equipment['sword']!.defense;
    }
    if (state.resources.containsKey('gun') && state.resources['gun']! > 0) {
      // 检查是否有子弹
      if (state.resources.containsKey('bullet') &&
          state.resources['bullet']! > 0) {
        totalAttack += equipment['gun']!.attack;
      }
    }
    if (state.resources.containsKey('armor') && state.resources['armor']! > 0) {
      totalDefense += equipment['armor']!.defense;
    }

    return {
      'attack': totalAttack,
      'defense': totalDefense,
    };
  }

  // 开始战斗
  bool startCombat(String enemyId, GameState state) {
    if (_combatState['inCombat']) return false;

    Enemy? enemy = enemies[enemyId];
    if (enemy == null) return false;

    // 设置战斗状态
    _combatState = {
      'inCombat': true,
      'currentEnemy': enemy,
      'enemyHealth': enemy.health,
      'playerHealth': 100, // 玩家基础生命值
      'turnsLeft': 10, // 战斗回合数
    };

    return true;
  }

  // 执行一个战斗回合
  Map<String, dynamic> executeCombatTurn(GameState state) {
    if (!_combatState['inCombat']) {
      return {'success': false, 'message': '未在战斗中'};
    }

    Enemy enemy = _combatState['currentEnemy'];
    Map<String, int> stats = getEquipmentStats(state);

    // 计算伤害，加入随机因素
    int playerAttack = stats['attack']!;
    int playerDamage = max(
        1, playerAttack - (enemy.defense * 0.7).floor() + _random.nextInt(3));
    int enemyDamage = max(1,
        enemy.attack - (stats['defense']! * 0.7).floor() + _random.nextInt(2));

    // 玩家攻击
    _combatState['enemyHealth'] -= playerDamage;

    // 检查是否击败敌人
    if (_combatState['enemyHealth'] <= 0) {
      return _endCombat(true, state);
    }

    // 敌人反击
    _combatState['playerHealth'] -= enemyDamage;

    // 检查玩家是否失败
    if (_combatState['playerHealth'] <= 0) {
      return _endCombat(false, state);
    }

    // 减少回合数
    _combatState['turnsLeft']--;
    if (_combatState['turnsLeft'] <= 0) {
      return _endCombat(false, state);
    }

    // 如果使用枪，消耗子弹
    if (state.resources.containsKey('gun') &&
        state.resources['gun']! > 0 &&
        state.resources.containsKey('bullet') &&
        state.resources['bullet']! > 0) {
      state.useResource('bullet', 1);
    }

    // Use language manager to get localized damage message
    String damageMessage = GameSettings.languageManager
        .get('damage_message', category: 'combat')
        .replaceAll('%d', '$playerDamage')
        .replaceFirst('%d', '$enemyDamage');

    return {
      'success': true,
      'message': damageMessage,
      'playerHealth': _combatState['playerHealth'],
      'enemyHealth': _combatState['enemyHealth'],
      'turnsLeft': _combatState['turnsLeft'],
    };
  }

  // 结束战斗
  Map<String, dynamic> _endCombat(bool victory, GameState state) {
    Enemy enemy = _combatState['currentEnemy'];
    Map<String, dynamic> result = {
      'success': true,
      'victory': victory,
      'message': victory
          ? GameSettings.languageManager.get('victory', category: 'combat')
          : GameSettings.languageManager.get('defeat', category: 'combat'),
      'loot': <String, int>{},
    };

    if (victory) {
      // 添加战利品
      enemy.loot.forEach((resource, amount) {
        state.addResource(resource, amount);
        (result['loot'] as Map<String, int>)[resource] = amount;
      });

      // 增加经验
      state.addExperience(enemy.experienceReward);
      result['experience'] = enemy.experienceReward;
    }

    // 重置战斗状态
    _combatState = Map<String, dynamic>.from(GameSettings.initialCombatState);

    return result;
  }

  // 检查是否在战斗中
  bool get isInCombat => _combatState['inCombat'] as bool;

  // 获取当前战斗状态
  Map<String, dynamic> getCombatState() =>
      Map<String, dynamic>.from(_combatState);

  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'combatState': _combatState,
    };
  }

  // 从JSON加载
  void fromJson(Map<String, dynamic> json) {
    if (json.containsKey('combatState')) {
      _combatState = Map<String, dynamic>.from(json['combatState']);
    }
  }

  // 清理资源
  void dispose() {
    _combatState = Map<String, dynamic>.from(GameSettings.initialCombatState);
  }
}
