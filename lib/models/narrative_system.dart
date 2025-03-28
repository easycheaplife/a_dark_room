import 'dart:math' as math;
import '../config/game_settings.dart';
import 'game_state.dart';
import 'game_event.dart';

/// 叙事系统管理游戏中的位置叙事和随机事件
class NarrativeSystem {
  final GameState gameState;

  // 缓存位置事件和随机事件
  late Map<String, dynamic> _locationEvents;
  late Map<String, dynamic> _randomEvents;

  // 已触发的事件ID集合
  final Set<String> _triggeredEventIds = {};

  // 上次触发事件的时间
  DateTime? _lastEventTime;

  // 构造函数
  NarrativeSystem(this.gameState) {
    _locationEvents = GameSettings.getLocationEvents();
    _randomEvents = GameSettings.getRandomEvents();
  }

  /// 获取位置叙事
  Map<String, dynamic>? getLocationNarrative(String locationType) {
    if (!_locationEvents.containsKey(locationType)) {
      return null;
    }

    var locationData = _locationEvents[locationType];

    // 根据当前语言获取相应的内容
    String lang = GameSettings.languageManager.currentLanguage;

    // 默认使用英语
    if (!locationData['title'].containsKey(lang)) {
      lang = 'en';
    }

    return {
      'title': locationData['title'][lang],
      'description': locationData['description'][lang],
      'events': _getLocationEventsForLanguage(locationData['events'], lang),
    };
  }

  /// 获取指定语言的位置事件列表
  List<Map<String, dynamic>> _getLocationEventsForLanguage(
      List<dynamic> events, String lang) {
    return events.map<Map<String, dynamic>>((event) {
      return {
        'id': event['id'],
        'title': event['title'][lang],
        'description': event['description'][lang],
        'chance': event['chance'],
        'outcome': event['outcome'],
      };
    }).toList();
  }

  /// 检查是否可以触发随机事件
  bool canTriggerRandomEvent() {
    // 确保有足够的时间间隔（防止事件过于频繁）
    if (_lastEventTime != null) {
      var timeSinceLastEvent = DateTime.now().difference(_lastEventTime!);
      if (timeSinceLastEvent.inMinutes < 5) {
        // 至少5分钟间隔
        return false;
      }
    }

    return true;
  }

  /// 获取随机事件
  Map<String, dynamic>? getRandomEvent() {
    if (!canTriggerRandomEvent()) {
      return null;
    }

    // 筛选符合条件的事件
    List<Map<String, dynamic>> eligibleEvents = [];

    _randomEvents.forEach((eventId, eventData) {
      // 跳过已触发的一次性事件
      if (eventData['oneTime'] == true &&
          _triggeredEventIds.contains(eventId)) {
        return;
      }

      // 检查事件触发条件
      if (_checkEventRequirements(eventData['requirements'])) {
        eligibleEvents.add({
          'id': eventId,
          ...eventData,
        });
      }
    });

    if (eligibleEvents.isEmpty) {
      return null;
    }

    // 基于权重随机选择一个事件
    final random = math.Random();
    double totalWeight = eligibleEvents.fold(
        0.0, (sum, event) => sum + (event['chance'] as double));
    double value = random.nextDouble() * totalWeight;

    double cumulativeWeight = 0.0;
    for (var event in eligibleEvents) {
      cumulativeWeight += event['chance'] as double;
      if (value <= cumulativeWeight) {
        // 记录触发时间
        _lastEventTime = DateTime.now();

        // 如果是一次性事件，记录已触发
        if (event['oneTime'] == true) {
          _triggeredEventIds.add(event['id']);
        }

        // 获取当前语言
        String lang = GameSettings.languageManager.currentLanguage;
        if (!event['title'].containsKey(lang)) {
          lang = 'en'; // 默认回退到英语
        }

        // 返回指定语言的事件数据
        return {
          'id': event['id'],
          'title': event['title'][lang],
          'description': event['description'][lang],
          'choices': _getChoicesForLanguage(event['choices'], lang),
        };
      }
    }

    return null;
  }

  /// 获取指定语言的选择列表
  List<Map<String, dynamic>> _getChoicesForLanguage(
      List<dynamic> choices, String lang) {
    return choices.map<Map<String, dynamic>>((choice) {
      return {
        'id': choice['id'],
        'text': choice['text'][lang],
        'effects': choice['effects'],
      };
    }).toList();
  }

  /// 检查事件触发条件
  bool _checkEventRequirements(Map<String, dynamic>? requirements) {
    if (requirements == null) {
      return true; // 没有条件，总是可以触发
    }

    // 检查资源要求
    if (requirements.containsKey('resources')) {
      Map<String, dynamic> resourceReqs = requirements['resources'];
      for (var resource in resourceReqs.keys) {
        int required = resourceReqs[resource];
        if (!gameState.resources.containsKey(resource) ||
            gameState.resources[resource]! < required) {
          return false;
        }
      }
    }

    // 检查建筑要求
    if (requirements.containsKey('buildings')) {
      Map<String, dynamic> buildingReqs = requirements['buildings'];
      for (var building in buildingReqs.keys) {
        int required = buildingReqs[building];
        int current = gameState.room['buildings'][building] ?? 0;
        if (current < required) {
          return false;
        }
      }
    }

    // 检查位置要求
    if (requirements.containsKey('location')) {
      String requiredLocation = requirements['location'];
      if (gameState.currentLocation != requiredLocation) {
        return false;
      }
    }

    return true;
  }

  /// 应用选择的效果
  void applyChoiceEffects(Choice choice) {
    Map<String, dynamic> effects = choice.effects;

    // 应用资源效果
    if (effects.containsKey('resources')) {
      Map<String, dynamic> resourceEffects = effects['resources'];
      for (var resource in resourceEffects.keys) {
        int value = resourceEffects[resource];
        if (value > 0) {
          gameState.addResource(resource, value);
        } else {
          gameState.useResource(resource, -value);
        }
      }
    }

    // 应用建筑效果
    if (effects.containsKey('buildings')) {
      Map<String, dynamic> buildingEffects = effects['buildings'];
      for (var building in buildingEffects.keys) {
        int value = buildingEffects[building];
        if (value > 0) {
          for (int i = 0; i < value; i++) {
            gameState.upgradeBuilding(building);
          }
        } else if (value < 0) {
          // 减少建筑
          Map<String, dynamic> buildings = gameState.room['buildings'];
          int current = buildings[building] ?? 0;
          buildings[building] = math.max(0, current + value);
        }
      }
    }

    // 应用人口效果
    if (effects.containsKey('population')) {
      int value = effects['population'];
      if (value > 0) {
        // 增加人口
        gameState.population['total'] =
            (gameState.population['total'] as int) + value;
      } else if (value < 0) {
        // 减少人口
        gameState.population['total'] =
            math.max(0, (gameState.population['total'] as int) + value);
      }
    }

    // 应用幸福度效果
    if (effects.containsKey('happiness')) {
      int value = effects['happiness'];
      gameState.population['happiness'] =
          (gameState.population['happiness'] as double) + value;
    }

    // 应用战斗效果
    if (effects.containsKey('combat')) {
      // 修复：正确传递参数到战斗系统
      if (effects.containsKey('enemy')) {
        String enemyType = effects['enemy'];
        gameState.combatSystem.startCombat(enemyType, gameState);
      }
    }

    // 延迟奖励效果
    if (effects.containsKey('delayedRewards')) {
      Map<String, dynamic> rewards = effects['delayedRewards'];
      int delayMinutes = rewards['time'] as int;

      // 创建延迟任务
      Future.delayed(Duration(minutes: delayMinutes), () {
        if (rewards.containsKey('resources')) {
          Map<String, dynamic> resourceRewards = rewards['resources'];
          for (var resource in resourceRewards.keys) {
            int value = resourceRewards[resource];
            gameState.addResource(resource, value);
          }
        }
      });
    }

    // 修改交易可用性
    if (effects.containsKey('tradeAvailable')) {
      bool available = effects['tradeAvailable'];
      gameState.storeOpened = available;
    }
  }

  /// 将原始事件数据转换为GameEvent对象
  GameEvent convertToGameEvent(Map<String, dynamic> eventData) {
    List<Choice> choices = (eventData['choices'] as List)
        .map((c) => Choice(
              id: c['id'],
              text: c['text'],
              effects: c['effects'],
            ))
        .toList();

    return GameEvent(
      id: eventData['id'],
      title: eventData['title'],
      description: eventData['description'],
      choices: choices,
    );
  }

  /// 将叙事系统状态转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'triggeredEventIds': _triggeredEventIds.toList(),
      'lastEventTime': _lastEventTime?.millisecondsSinceEpoch,
    };
  }

  /// 从JSON加载叙事系统状态
  void fromJson(Map<String, dynamic> json) {
    if (json.containsKey('triggeredEventIds')) {
      _triggeredEventIds.clear();
      _triggeredEventIds
          .addAll((json['triggeredEventIds'] as List).cast<String>());
    }

    if (json.containsKey('lastEventTime') && json['lastEventTime'] != null) {
      _lastEventTime =
          DateTime.fromMillisecondsSinceEpoch(json['lastEventTime'] as int);
    } else {
      _lastEventTime = null;
    }
  }
}
