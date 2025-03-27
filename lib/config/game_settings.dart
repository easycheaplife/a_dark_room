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
}
