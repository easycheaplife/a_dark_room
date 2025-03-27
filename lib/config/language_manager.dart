import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 语言管理器 - 用于处理游戏中的多语言支持
class LanguageManager extends ChangeNotifier {
  static const String LANG_PREF_KEY = 'selected_language';
  static const String DEFAULT_LANGUAGE = 'zh'; // 默认使用中文

  // 支持的语言
  static const Map<String, String> SUPPORTED_LANGUAGES = {
    'zh': '中文',
    'en': 'English',
  };

  // 当前选择的语言
  String _currentLanguage = DEFAULT_LANGUAGE;

  // 获取当前语言
  String get currentLanguage => _currentLanguage;

  // 单例模式
  static final LanguageManager _instance = LanguageManager._internal();

  // 工厂构造函数
  factory LanguageManager() {
    return _instance;
  }

  // 内部构造函数
  LanguageManager._internal();

  // 翻译文本集合
  static Map<String, Map<String, Map<String, String>>> _translations = {
    'en': {
      'common': {
        'save_success': 'Game saved successfully',
        'save_failed': 'Failed to save game',
        'back': 'Back',
        'confirm': 'Confirm',
        'cancel': 'Cancel',
        'language_changed': 'Language changed to English',
        'own': 'Owned',
        'buy': 'Buy',
        'sell': 'Sell',
        'level': 'Lv',
        'price_update': 'Prices update every 5 minutes',
        'to_level': 'to level',
        'requires': 'Requires',
        'seconds': 's',
        'unknown': 'Unknown',
      },
      'room': {
        'dark_room': 'Dark Room',
        'fire_status': 'Fire Status',
        'temperature': 'Temperature',
        'no_fire': 'It\'s dark and cold.\nNeed to light a fire.',
        'fire_smoldering': 'The fire crackles.',
        'fire_burning': 'The fire burns well.',
        'fire_roaring': 'The fire roars.',
        'cold': 'Cold',
        'mild': 'Mild',
        'warm': 'Warm',
        'hot': 'Hot',
        'worker_status': 'Worker Status',
        'efficiency': 'Efficiency',
        'gathered_wood': 'Gathered some wood.',
        'fire_lit': 'The fire is lit. The room warms up.',
        'not_enough_wood': 'Not enough wood.',
        'no_fire_pit': 'There is no fire.',
        'fire_burns_brighter': 'The fire burns brighter.',
        'no_wood': 'No wood.',
      },
      'actions': {
        'light_fire': 'Light Fire',
        'add_wood': 'Add Wood',
        'gather_wood': 'Gather Wood',
        'build': 'Build',
        'villagers': 'Villagers',
        'trade': 'Trade',
        'craft': 'Craft',
        'explore': 'Explore',
        'exploring': 'Exploring',
        'scavenge': 'Scavenge',
        'scavenging': 'Scavenging',
        'save': 'Save',
        'small_hunt': 'Small Hunt',
        'large_hunt': 'Large Hunt',
        'gather_water': 'Gather Water',
        'gathering_water': 'Gathering Water...',
        'return_room': 'Return to Room',
        'return_to_village': 'Return to Village',
        'explore_wilderness': 'Explore Wilderness',
      },
      'menu': {
        'game_menu': 'Game Menu',
        'go_outside': 'Go Outside',
        'explore_path': 'Explore Paths',
        'test_path': 'Test Path System',
        'enter_world': 'Enter World Map',
        'add_resources': 'Add Resources',
        'unlock_all': 'Unlock All Features',
        'resources_added': 'Resources added',
        'all_unlocked': 'All features unlocked',
        'language': 'Language',
        'path_error': 'Error entering path system',
      },
      'resource_groups': {
        'basic_resources': 'Basic Resources',
        'hunting_resources': 'Hunting Resources',
        'crafting_materials': 'Crafting Materials',
        'food': 'Food',
      },
      'resources': {
        'wood': 'Wood',
        'fur': 'Fur',
        'meat': 'Meat',
        'scales': 'Scales',
        'teeth': 'Teeth',
        'leather': 'Leather',
        'cloth': 'Cloth',
        'cured meat': 'Cured Meat',
        'iron': 'Iron',
        'coal': 'Coal',
        'steel': 'Steel',
        'medicine': 'Medicine',
        'bullets': 'Bullets',
        'energy cell': 'Energy Cell',
        'money': 'Money',
        'water': 'Water',
      },
      'trade': {
        'sold': 'Sold',
        'bought': 'Bought',
        'buy': 'Buy',
        'sell': 'Sell',
      },
      'villagers': {
        'wood_gatherer': 'Wood Gatherer',
        'hunter': 'Hunter',
        'trapper': 'Trapper',
        'tanner': 'Tanner',
        'miner': 'Miner',
        'coal_miner': 'Coal Miner',
        'iron_miner': 'Iron Miner',
        'builder': 'Builder',
        'scout': 'Scout',
        'total_population': 'Total Population',
        'happiness': 'Happiness',
        'gatherer': 'Gatherer',
        'craftsman': 'Craftsman',
        'gatherer_desc': 'Collects wood and food',
        'hunter_desc': 'Specializes in hunting animals',
        'builder_desc': 'Builds and maintains structures',
        'craftsman_desc': 'Creates advanced items',
        'recruited': 'Recruited a',
      },
      'world': {
        'world_map': 'World Map',
        'move': 'Move',
        'current_location': 'Current Location',
        'food_available': 'Food Available',
        'no_food': 'No Food',
        'village': 'Village',
        'map_loading': 'Map Loading...',
      },
      'buildings': {
        'upgrade_to': 'Upgrade to',
        'upgrade_success': 'Upgraded',
        'maintenance': 'Maintenance',
        'trap': 'Trap',
        'cart': 'Cart',
        'hut': 'Hut',
        'lodge': 'Lodge',
        'trading_post': 'Trading Post',
        'tannery': 'Tannery',
        'smokehouse': 'Smokehouse',
        'weapons': 'Weapons',
        'workshop': 'Workshop',
        'steelworks': 'Steelworks',
        'armoury': 'Armoury',
        'well': 'Well',
        'mine': 'Mine',
        'trap_desc': 'Captures wild animals',
        'cart_desc': 'Increases carrying capacity',
        'hut_desc': 'Provides shelter for villagers',
        'lodge_desc': 'Trains skilled hunters',
        'trading_post_desc': 'Allows trading with merchants',
        'tannery_desc': 'Processes fur into leather',
        'smokehouse_desc': 'Preserves meat',
        'weapons_desc': 'Makes hunting weapons',
        'workshop_desc': 'Creates advanced tools',
        'steelworks_desc': 'Converts iron into steel',
        'armoury_desc': 'Manufactures weapons and armor',
        'well_desc': 'Provides stable water source',
        'mine_desc': 'Excavates iron and coal',
      },
      'combat': {
        'combat_title': 'Combat - ',
        'enemy_health': 'Enemy Health',
        'player_health': 'Your Health',
        'turns_left': 'Turns Left',
        'attack': 'Attack',
        'flee': 'Flee',
        'victory': 'Victory!',
        'defeat': 'Defeat...',
        'combat_round': 'Round',
        'wolf': 'Wolf',
        'bear': 'Bear',
        'snake': 'Snake',
        'bat': 'Bat',
        'spider': 'Spider',
        'crocodile': 'Crocodile',
        'scorpion': 'Scorpion',
        'ghost': 'Ghost',
        'bandit': 'Bandit',
        'damage_message': 'Dealt %d damage, received %d damage',
        'encountered': 'Encountered a %s!',
        'enemy_health_fraction': 'Enemy Health: %d / %d',
        'player_health_fraction': 'Your Health: %d / %d',
        'turns_left_value': 'Turns Left: %d',
        'small_hunt': 'Small Hunt',
        'large_hunt': 'Large Hunt',
        'loot_gained': 'Gained loot:',
        'experience_gained': 'Gained experience:',
        'fled_combat': 'Fled from combat',
      },
      'path': {
        'prepare_exploration': 'Prepare Exploration',
        'retry': 'Retry',
        'return_to_room': 'Return to Room',
        'embark_error': 'Cannot embark: Need to carry some cured meat',
        'going_to_world': 'Going to world...',
        'cannot_embark': 'Cannot embark, check your bag',
        'error': 'Error: ',
      },
      'outfit': {
        'prepare_to_depart': 'Prepare to Depart',
        'bag_space': 'Bag Space',
        'weight': 'Weight',
        'available': 'Available',
        'return': 'Return',
        'depart': 'Depart',
      },
      'navigation': {
        'room_btn': 'Room',
        'store_btn': 'Store',
        'hunt_btn': 'Hunt',
        'craft_btn': 'Craft',
        'smoke_btn': 'Smoke',
        'workshop_btn': 'Work',
        'steel_btn': 'Steel',
        'armory_btn': 'Arms',
        'trap_btn': 'Trap',
        'water_btn': 'Water',
        'mine_btn': 'Mine',
      },
      'locations': {
        'outside': 'Outside',
        'forest': 'Forest',
        'forest_desc': 'A dense forest with abundant resources.',
        'current_location': 'Current Location',
        'exploring_in': 'Exploring in',
        'scavenging_in': 'Scavenging in',
      },
      'crafting': {
        'requires': 'Requires',
        'output': 'Output',
        'ingredients': 'Ingredients',
        'recipe': 'Recipe',
        'name': 'Name',
        'description': 'Description',
      },
      'save': {
        'save_directory': 'Save Directory',
        'auto_save': 'Auto Save',
        'last_auto_save': 'Last Auto Save',
        'save_slot': 'Save',
        'empty_save': 'Empty Save',
        'location': 'Location',
        'population': 'Population',
        'time': 'Time',
        'clear_all_saves': 'Clear All Saves',
        'confirm_clear': 'Confirm Clear All Saves',
        'confirm_clear_message':
            'Are you sure you want to clear all saves? This action cannot be undone.',
        'confirm_delete': 'Confirm Delete',
        'confirm_delete_message': 'Are you sure you want to delete save',
        'delete': 'Delete',
        'auto_save_enabled': 'Auto save enabled',
        'auto_save_disabled': 'Auto save disabled',
        'load_success': 'Loaded game from save',
        'load_failed': 'Failed to load save',
        'delete_success': 'Deleted save',
        'clear_success': 'All saves cleared',
        'clear_failed': 'Failed to clear saves',
      },
    },
    'zh': {
      'common': {
        'save_success': '游戏保存成功',
        'save_failed': '保存游戏失败',
        'back': '返回',
        'confirm': '确认',
        'cancel': '取消',
        'language_changed': '语言已切换为中文',
        'own': '持有',
        'buy': '买入',
        'sell': '卖出',
        'level': '级',
        'price_update': '价格每5分钟更新一次',
        'to_level': '到',
        'requires': '需要',
        'seconds': '秒',
        'unknown': '未知',
      },
      'room': {
        'dark_room': '黑暗的房间',
        'fire_status': '火堆状态',
        'temperature': '温度',
        'no_fire': '这里很黑，很冷。\n需要生火。',
        'fire_smoldering': '火堆噼啪作响。',
        'fire_burning': '火堆燃烧得很好。',
        'fire_roaring': '火堆熊熊燃烧。',
        'cold': '寒冷',
        'mild': '微温',
        'warm': '温暖',
        'hot': '炎热',
        'worker_status': '工作状态',
        'efficiency': '效率',
        'gathered_wood': '收集了一些木头。',
        'fire_lit': '火堆点燃了。房间变暖了。',
        'not_enough_wood': '没有足够的木头。',
        'no_fire_pit': '没有火堆。',
        'fire_burns_brighter': '火堆燃烧更旺了。',
        'no_wood': '没有木头。',
      },
      'actions': {
        'light_fire': '生火',
        'add_wood': '添加木头',
        'gather_wood': '收集木头',
        'build': '建造',
        'villagers': '村民',
        'trade': '交易',
        'craft': '制作',
        'explore': '探索',
        'exploring': '探索中',
        'scavenge': '搜索',
        'scavenging': '搜索中',
        'save': '保存',
        'small_hunt': '小型狩猎',
        'large_hunt': '大型狩猎',
        'gather_water': '收集水',
        'gathering_water': '正在收集水...',
        'return_room': '返回房间',
        'return_to_village': '返回村庄',
        'explore_wilderness': '探索荒野',
      },
      'menu': {
        'game_menu': '游戏菜单',
        'go_outside': '出门',
        'explore_path': '探索小径',
        'test_path': '测试路径系统',
        'enter_world': '进入世界地图',
        'add_resources': '添加资源',
        'unlock_all': '解锁所有功能',
        'resources_added': '资源已添加',
        'all_unlocked': '所有功能已解锁',
        'language': '语言',
        'path_error': '进入路径系统时出错',
      },
      'resource_groups': {
        'basic_resources': '基础资源',
        'hunting_resources': '狩猎资源',
        'crafting_materials': '制作材料',
        'food': '食物',
      },
      'resources': {
        'wood': '木头',
        'fur': '毛皮',
        'meat': '肉',
        'scales': '鳞片',
        'teeth': '牙齿',
        'leather': '皮革',
        'cloth': '布料',
        'cured meat': '腌肉',
        'iron': '铁',
        'coal': '煤',
        'steel': '钢',
        'medicine': '药品',
        'bullets': '子弹',
        'energy cell': '能量电池',
        'money': '钱',
        'water': '水',
      },
      'trade': {
        'sold': '卖出了',
        'bought': '购买了',
        'buy': '买入',
        'sell': '卖出',
      },
      'villagers': {
        'wood_gatherer': '伐木工',
        'hunter': '猎人',
        'trapper': '陷阱师',
        'tanner': '制革工',
        'miner': '矿工',
        'coal_miner': '煤矿工',
        'iron_miner': '铁矿工',
        'builder': '建筑工',
        'scout': '侦察兵',
        'total_population': '总人口',
        'happiness': '幸福度',
        'gatherer': '采集者',
        'craftsman': '工匠',
        'gatherer_desc': '收集木材和食物',
        'hunter_desc': '专门狩猎动物',
        'builder_desc': '建造和维护建筑',
        'craftsman_desc': '制作高级物品',
        'recruited': '招募了一个',
      },
      'world': {
        'world_map': '世界地图',
        'move': '移动',
        'current_location': '当前位置',
        'food_available': '食物充足',
        'no_food': '没有食物',
        'village': '村庄',
        'map_loading': '地图生成中...',
      },
      'buildings': {
        'upgrade_to': '升级到',
        'upgrade_success': '升级了',
        'maintenance': '维护',
        'trap': '陷阱',
        'cart': '货车',
        'hut': '小屋',
        'lodge': '猎人小屋',
        'trading_post': '交易站',
        'tannery': '制革厂',
        'smokehouse': '熏肉房',
        'weapons': '武器工坊',
        'workshop': '工坊',
        'steelworks': '炼钢厂',
        'armoury': '军械库',
        'well': '水井',
        'mine': '矿场',
        'trap_desc': '捕捉野生动物',
        'cart_desc': '增加携带容量',
        'hut_desc': '为村民提供住所',
        'lodge_desc': '训练熟练的猎人',
        'trading_post_desc': '与商人交易物资',
        'tannery_desc': '将毛皮制成皮革',
        'smokehouse_desc': '保存肉类',
        'weapons_desc': '制作狩猎武器',
        'workshop_desc': '制作高级工具',
        'steelworks_desc': '将铁转化为钢',
        'armoury_desc': '制造武器和盔甲',
        'well_desc': '提供稳定的水源',
        'mine_desc': '开采铁和煤',
      },
      'combat': {
        'combat_title': '战斗 - ',
        'enemy_health': '敌人生命值',
        'player_health': '你的生命值',
        'turns_left': '剩余回合',
        'attack': '攻击',
        'flee': '逃跑',
        'victory': '战斗胜利！',
        'defeat': '战斗失败...',
        'combat_round': '回合',
        'wolf': '狼',
        'bear': '熊',
        'snake': '毒蛇',
        'bat': '蝙蝠',
        'spider': '蜘蛛',
        'crocodile': '鳄鱼',
        'scorpion': '蝎子',
        'ghost': '幽灵',
        'bandit': '强盗',
        'damage_message': '造成了 %d 点伤害，受到了 %d 点伤害',
        'encountered': '遭遇了%s！',
        'enemy_health_fraction': '敌人生命值: %d / %d',
        'player_health_fraction': '你的生命值: %d / %d',
        'turns_left_value': '剩余回合: %d',
        'small_hunt': '小型狩猎',
        'large_hunt': '大型狩猎',
        'loot_gained': '获得了战利品：',
        'experience_gained': '获得了经验：',
        'fled_combat': '逃离了战斗',
      },
      'path': {
        'prepare_exploration': '探索准备',
        'retry': '重试',
        'return_to_room': '返回房间',
        'embark_error': '无法出发: 需要至少携带一些熏肉',
        'going_to_world': '正在前往世界...',
        'cannot_embark': '无法出发，请检查背包',
        'error': '出错: ',
      },
      'outfit': {
        'prepare_to_depart': '准备出发',
        'bag_space': '背包空间',
        'weight': '重量',
        'available': '可用',
        'return': '返回',
        'depart': '出发',
      },
      'navigation': {
        'room_btn': '小',
        'store_btn': '货',
        'hunt_btn': '猎',
        'craft_btn': '制',
        'smoke_btn': '熏',
        'workshop_btn': '工',
        'steel_btn': '炼',
        'armory_btn': '军',
        'trap_btn': '陷',
        'water_btn': '水',
        'mine_btn': '矿',
      },
      'locations': {
        'outside': '村外',
        'forest': '森林',
        'forest_desc': '一片茂密的森林，有丰富的资源。',
        'current_location': '当前位置',
        'exploring_in': '正在探索',
        'scavenging_in': '正在搜索',
      },
      'crafting': {
        'requires': '需要',
        'output': '产出',
        'ingredients': '材料',
        'recipe': '配方',
        'name': '名称',
        'description': '描述',
      },
      'save': {
        'save_directory': '存档目录',
        'auto_save': '自动存档',
        'last_auto_save': '上次自动存档',
        'save_slot': '存档',
        'empty_save': '空存档',
        'location': '位置',
        'population': '人口',
        'time': '时间',
        'clear_all_saves': '清除所有存档',
        'confirm_clear': '确认清除所有存档',
        'confirm_clear_message': '确定要清除所有存档吗？此操作不可恢复。',
        'confirm_delete': '确认删除',
        'confirm_delete_message': '确定要删除存档',
        'delete': '删除',
        'auto_save_enabled': '已启用自动存档',
        'auto_save_disabled': '已禁用自动存档',
        'load_success': '从存档加载了游戏',
        'load_failed': '加载存档失败',
        'delete_success': '删除了存档',
        'clear_success': '已清除所有存档',
        'clear_failed': '清除存档失败',
      },
    },
  };

  // 初始化
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentLanguage = prefs.getString(LANG_PREF_KEY) ?? DEFAULT_LANGUAGE;

      if (kDebugMode) {
        print('当前语言: $_currentLanguage');
      }
    } catch (e) {
      if (kDebugMode) {
        print('初始化语言设置失败: $e');
      }
      _currentLanguage = DEFAULT_LANGUAGE;
    }
  }

  // 切换语言
  Future<void> setLanguage(String languageCode) async {
    if (!SUPPORTED_LANGUAGES.containsKey(languageCode)) {
      if (kDebugMode) {
        print('不支持的语言: $languageCode');
      }
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(LANG_PREF_KEY, languageCode);

      _currentLanguage = languageCode;
      notifyListeners();

      if (kDebugMode) {
        print('语言已切换为: $_currentLanguage');
      }
    } catch (e) {
      if (kDebugMode) {
        print('保存语言设置失败: $e');
      }
    }
  }

  // 获取当前语言的文本
  String get(String key, {String category = 'common'}) {
    try {
      return _translations[currentLanguage]![category]![key] ?? key;
    } catch (e) {
      if (kDebugMode) {
        print('Language key not found: $category/$key');
      }
      return key;
    }
  }

  // 检查是否有翻译
  bool hasTranslation(String key, {String? category}) {
    final cat = category ?? 'common';
    final fullKey = '${key}_$_currentLanguage';

    return _translations.containsKey(cat) &&
        _translations[cat]!.containsKey(fullKey);
  }

  // 添加语言翻译(开发中使用)
  void addTranslation(
      String category, String key, String value, String language) {
    if (!_translations.containsKey(language)) {
      _translations[language] = {};
    }
    if (!_translations[language]!.containsKey(category)) {
      _translations[language]![category] = {};
    }
    _translations[language]![category]![key] = value;
  }

  // 导出所有翻译为JSON(开发中使用)
  String exportTranslations() {
    return jsonEncode(_translations);
  }
}
