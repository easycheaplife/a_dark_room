import 'package:flutter/foundation.dart';
import 'language_manager.dart';

/// 游戏设置 - 集中管理游戏配置和设置
class GameSettings {
  // 资源存储上限
  static const Map<String, int> resourceLimits = {
    'wood': 100,
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
  static const Map<String, Map<String, dynamic>> availableBuildings = {
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
    'weapons': {
      'name': '武器工坊',
      'description': '制作狩猎武器',
      'cost': {
        'wood': 50,
        'iron': 20,
        'steel': 10,
      },
      'notification': '武器工坊可以制作更好的狩猎武器了。',
      'requires': {
        'buildings': {'trading_post': 1}
      },
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
    'mine': {
      'name': '矿场',
      'description': '开采铁和煤',
      'cost': {
        'wood': 200,
        'leather': 50,
      },
      'notification': '矿工开始工作了。',
      'requires': {
        'buildings': {'trading_post': 1}
      },
    },
  };

  // 村民类型定义
  static const Map<String, Map<String, dynamic>> villagerTypes = {
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

  // 建筑维护成本
  static const Map<String, Map<String, dynamic>> buildingMaintenance = {
    'mine': {
      'wood': 2,
      'leather': 1,
      'interval': 60, // 每60秒维护一次
    },
    'lodge': {
      'meat': 1,
      'wood': 1,
      'interval': 120, // 每120秒维护一次
    },
  };

  // 建筑升级效果
  static Map<String, Map<String, dynamic>> getBuildingUpgradeEffects(
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

  // 狩猎结果配置
  static const Map<String, Map<String, dynamic>> huntingOutcomes = {
    'small_game': {
      'name': '小型猎物',
      'outcomes': {
        'meat': {'min': 100, 'max': 300},
        'fur': {'min': 100, 'max': 200},
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

  // 敌人配置
  static const Map<String, Map<String, dynamic>> enemies = {
    'wolf': {
      'name': '狼',
      'health': 5,
      'attack': 2,
      'defense': 1,
      'loot': ['fur', 'meat'],
      'loot_chance': 0.7,
    },
    'bear': {
      'name': '熊',
      'health': 8,
      'attack': 4,
      'defense': 2,
      'loot': ['fur', 'meat'],
      'loot_chance': 0.8,
    },
    'snake': {
      'name': '毒蛇',
      'health': 3,
      'attack': 1,
      'defense': 0,
      'loot': ['venom'],
      'loot_chance': 0.6,
    },
    'bat': {
      'name': '蝙蝠',
      'health': 2,
      'attack': 1,
      'defense': 0,
      'loot': ['leather'],
      'loot_chance': 0.5,
    },
    'spider': {
      'name': '蜘蛛',
      'health': 4,
      'attack': 2,
      'defense': 1,
      'loot': ['silk'],
      'loot_chance': 0.6,
    },
    'crocodile': {
      'name': '鳄鱼',
      'health': 7,
      'attack': 3,
      'defense': 2,
      'loot': ['leather', 'teeth'],
      'loot_chance': 0.7,
    },
    'scorpion': {
      'name': '蝎子',
      'health': 3,
      'attack': 2,
      'defense': 1,
      'loot': ['venom'],
      'loot_chance': 0.6,
    },
    'ghost': {
      'name': '幽灵',
      'health': 6,
      'attack': 3,
      'defense': 0,
      'loot': ['ectoplasm'],
      'loot_chance': 0.5,
    },
  };

  // 战斗系统配置
  static const Map<String, dynamic> combatConfig = {
    'in_combat': false,
    'current_enemy': null,
    'combat_round': 0,
    'player_health': 10,
    'player_max_health': 10,
    'player_attack': 2,
    'player_defense': 1,
    'inventory': [],
  };

  // 玩家状态配置
  static const Map<String, dynamic> playerStatsConfig = {
    'level': 1,
    'experience': 0,
    'nextLevelExperience': 100,
  };

  // 事件系统配置
  static const Map<String, Map<String, dynamic>> eventConfigs = {
    'stranger': {
      'id': 'stranger',
      'title': '陌生人',
      'description': '一个陌生人出现在门外。',
      'requirements': {
        'buildings': {'hut': 1},
      },
      'effects': {},
      'choices': [
        {
          'text': '欢迎',
          'effects': {
            'population': 1,
            'happiness': 5,
          },
        },
        {
          'text': '赶走',
          'effects': {
            'happiness': -5,
          },
        },
      ],
    },
    'trader': {
      'id': 'trader',
      'title': '商人',
      'description': '一个商人想要交易。',
      'requirements': {
        'buildings': {'trading_post': 1},
      },
      'effects': {},
      'choices': [
        {
          'text': '交易',
          'effects': {
            'trade_available': true,
          },
        },
        {
          'text': '拒绝',
          'effects': {},
        },
      ],
    },
    'storm': {
      'id': 'storm',
      'title': '暴风雨',
      'description': '一场暴风雨正在接近。',
      'requirements': {
        'outside_unlocked': true,
      },
      'effects': {
        'wood': -10,
        'happiness': -10,
      },
      'choices': null,
    },
  };

  // 交易物品配置
  static const Map<String, Map<String, dynamic>> tradeItemConfigs = {
    'fur': {
      'resourceId': 'fur',
      'name': '毛皮',
      'basePrice': 10,
      'priceVariation': 0.3,
      'maxAmount': 100,
    },
    'leather': {
      'resourceId': 'leather',
      'name': '皮革',
      'basePrice': 15,
      'priceVariation': 0.25,
      'maxAmount': 100,
    },
    'iron': {
      'resourceId': 'iron',
      'name': '铁',
      'basePrice': 20,
      'priceVariation': 0.2,
      'maxAmount': 50,
    },
    'steel': {
      'resourceId': 'steel',
      'name': '钢',
      'basePrice': 40,
      'priceVariation': 0.15,
      'maxAmount': 30,
    },
    'cloth': {
      'resourceId': 'cloth',
      'name': '布料',
      'basePrice': 8,
      'priceVariation': 0.35,
      'maxAmount': 150,
    },
  };

  // 制作配方配置
  static const Map<String, Map<String, dynamic>> craftingRecipeConfigs = {
    'cured_meat': {
      'id': 'cured_meat',
      'name': '熏肉',
      'description': '将生肉制成可以长期保存的熏肉',
      'ingredients': {
        'meat': 2,
        'wood': 1,
      },
      'outputs': {
        'cured meat': 1,
      },
      'craftingTime': 30,
      'requirements': {
        'buildings': {'smokehouse': 1},
      },
    },
    'leather': {
      'id': 'leather',
      'name': '皮革',
      'description': '将毛皮加工成皮革',
      'ingredients': {
        'fur': 2,
        'water': 1,
      },
      'outputs': {
        'leather': 1,
      },
      'craftingTime': 20,
      'requirements': {
        'buildings': {'tannery': 1},
      },
    },
    'steel': {
      'id': 'steel',
      'name': '钢',
      'description': '将铁和煤炼制成钢',
      'ingredients': {
        'iron': 2,
        'coal': 1,
      },
      'outputs': {
        'steel': 1,
      },
      'craftingTime': 40,
      'requirements': {
        'buildings': {'steelworks': 1},
      },
    },
    'cloth': {
      'id': 'cloth',
      'name': '布料',
      'description': '将毛皮制成布料',
      'ingredients': {
        'fur': 3,
        'water': 2,
      },
      'outputs': {
        'cloth': 1,
      },
      'craftingTime': 25,
      'requirements': {
        'buildings': {'workshop': 1},
      },
    },
    'rope': {
      'id': 'rope',
      'name': '绳索',
      'description': '用布料制作结实的绳索',
      'ingredients': {
        'cloth': 2,
        'leather': 1,
      },
      'outputs': {
        'rope': 1,
      },
      'craftingTime': 15,
      'requirements': {
        'buildings': {'workshop': 1},
      },
    },
    'medicine': {
      'id': 'medicine',
      'name': '药品',
      'description': '用草药制作治疗药品',
      'ingredients': {
        'herbs': 3,
        'water': 1,
      },
      'outputs': {
        'medicine': 1,
      },
      'craftingTime': 20,
      'requirements': {
        'buildings': {'workshop': 1},
      },
    },
    'sword': {
      'id': 'sword',
      'name': '剑',
      'description': '制作一把锋利的剑',
      'ingredients': {
        'steel': 2,
        'wood': 1,
        'leather': 1,
      },
      'outputs': {
        'sword': 1,
      },
      'craftingTime': 45,
      'requirements': {
        'buildings': {'workshop': 1},
      },
    },
    'armor': {
      'id': 'armor',
      'name': '盔甲',
      'description': '制作一套防护盔甲',
      'ingredients': {
        'steel': 3,
        'leather': 2,
        'cloth': 1,
      },
      'outputs': {
        'armor': 1,
      },
      'craftingTime': 60,
      'requirements': {
        'buildings': {'workshop': 1},
      },
    },
    'gunpowder': {
      'id': 'gunpowder',
      'name': '火药',
      'description': '制作火药',
      'ingredients': {
        'sulphur': 2,
        'coal': 1,
      },
      'outputs': {
        'gunpowder': 1,
      },
      'craftingTime': 30,
      'requirements': {
        'buildings': {'workshop': 1},
      },
    },
    'bullet': {
      'id': 'bullet',
      'name': '子弹',
      'description': '制作子弹',
      'ingredients': {
        'steel': 1,
        'gunpowder': 1,
      },
      'outputs': {
        'bullet': 5,
      },
      'craftingTime': 20,
      'requirements': {
        'buildings': {'workshop': 1},
      },
    },
    'gun': {
      'id': 'gun',
      'name': '枪',
      'description': '制作一把枪',
      'ingredients': {
        'steel': 3,
        'wood': 2,
        'gunpowder': 1,
      },
      'outputs': {
        'gun': 1,
      },
      'craftingTime': 75,
      'requirements': {
        'buildings': {'workshop': 1},
      },
    },
  };

  // UI配置
  static const Map<String, List<String>> resourceGroups = {
    '基础资源': ['wood', 'meat', 'water'],
    '狩猎资源': ['fur', 'scales', 'teeth', 'leather'],
    '制作材料': ['cloth', 'herbs', 'coal', 'iron', 'steel', 'sulphur'],
    '食物': ['cured meat'],
  };

  static const Map<String, Map<String, dynamic>> locationConfigs = {
    'cave': {
      'name': '洞穴',
      'description': '一个黑暗的洞穴，可能藏有宝藏。',
      'resources': ['coal', 'iron', 'sulphur'],
      'dangers': ['bat', 'spider'],
      'exploration_time': 30,
      'scavenging_time': 20,
      'hunting_time': 15,
    },
    'river': {
      'name': '河流',
      'description': '一条清澈的河流，有丰富的鱼类资源。',
      'resources': ['water', 'fish'],
      'dangers': ['crocodile'],
      'exploration_time': 30,
      'scavenging_time': 20,
      'hunting_time': 15,
    },
    'mountain': {
      'name': '山脉',
      'description': '陡峭的山脉，富含矿物。',
      'resources': ['iron', 'coal', 'stone'],
      'dangers': ['bear'],
      'exploration_time': 30,
      'scavenging_time': 20,
      'hunting_time': 15,
    },
    'desert': {
      'name': '沙漠',
      'description': '一片荒芜的沙漠，有稀有的资源。',
      'resources': ['sand', 'cactus'],
      'dangers': ['scorpion'],
      'exploration_time': 30,
      'scavenging_time': 20,
      'hunting_time': 15,
    },
    'swamp': {
      'name': '沼泽',
      'description': '潮湿的沼泽地，有独特的资源。',
      'resources': ['herbs', 'mushroom'],
      'dangers': ['snake'],
      'exploration_time': 30,
      'scavenging_time': 20,
      'hunting_time': 15,
    },
    'ruins': {
      'name': '废墟',
      'description': '古老的废墟，可能藏有珍贵的物品。',
      'resources': ['scrap', 'artifact'],
      'dangers': ['ghost'],
      'exploration_time': 30,
      'scavenging_time': 20,
      'hunting_time': 15,
    },
  };

  static const List<String> possibleLocations = [
    'cave',
    'river',
    'mountain',
    'desert',
    'swamp',
    'ruins',
  ];

  // 火堆配置
  static const Map<String, Map<String, String>> fireConfigs = {
    'colors': {
      '0': 'grey700', // 无火
      '1': 'orange300', // 余烬
      '2': 'orange', // 燃烧
      '3': 'deepOrange', // 熊熊燃烧
    },
    'descriptions': {
      '0': 'no_fire', // '无火'
      '1': 'fire_smoldering', // '余烬'
      '2': 'fire_burning', // '燃烧'
      '3': 'fire_roaring', // '熊熊燃烧'
    },
    'effects': {
      '0': 'cold', // 寒冷
      '1': 'mild', // 微温
      '2': 'warm', // 温暖
      '3': 'hot', // 炎热
    },
  };

  // 初始资源值
  static const Map<String, int> initialResources = {
    'wood': 1,
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
    'water': 0,
    'money': 100,
  };

  // 资源生产和效率配置
  static const Map<String, double> resourceProductionMultipliers = {
    'iron': 1.0,
    'steel': 1.0,
    'wood': 1.0,
    'coal': 1.0,
  };

  static const Map<String, double> resourceEfficiency = {
    'iron': 1.0,
    'steel': 1.0,
    'wood': 1.0,
    'coal': 1.0,
  };

  // 存档配置
  static const String SAVE_DIRECTORY = 'saves';
  static const int MAX_SAVE_SLOTS = 3;

  // 战斗系统初始状态
  static const Map<String, dynamic> initialCombatState = {
    'inCombat': false,
    'currentEnemy': null,
    'enemyHealth': 0,
    'playerHealth': 0,
    'turnsLeft': 0,
  };

  // 资源收集配置
  static const Map<String, Map<String, dynamic>> resourceGatheringConfigs = {
    'wood': {
      'base_amount': 1,
      'time': 5, // 收集时间（秒）
      'tool_multiplier': 1.5, // 使用工具时的倍率
    },
    'water': {
      'base_amount': 1,
      'time': 3,
      'tool_multiplier': 1.2,
    },
    'herbs': {
      'base_amount': 1,
      'time': 4,
      'tool_multiplier': 1.3,
    },
    'stone': {
      'base_amount': 1,
      'time': 6,
      'tool_multiplier': 1.4,
    },
  };

  // 开发者相关设置
  static const bool DEV_MODE = true;

  // 开发者选项
  static const Map<String, bool> DEV_OPTIONS = {
    'QUICK_TEST_PATH': false, // 快速测试路径系统
    'UNLIMITED_RESOURCES': true, // 无限资源
    'SKIP_TUTORIALS': true, // 跳过教程
    'UNLOCK_ALL': false, // 解锁所有内容
  };

  // 语言管理器
  static final LanguageManager languageManager = LanguageManager();

  // 初始化设置
  static Future<void> init() async {
    // 初始化语言设置
    await languageManager.init();

    if (kDebugMode) {
      print('游戏设置初始化完成');
      print('开发者模式: $DEV_MODE');
      print('当前语言: ${languageManager.currentLanguage}');
    }
  }
}
