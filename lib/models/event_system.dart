import 'dart:math';
import 'game_state.dart';

class Choice {
  final String text;
  final Map<String, dynamic> effects;
  final Map<String, dynamic>? requirements;

  Choice({
    required this.text,
    required this.effects,
    this.requirements,
  });
}

class GameEvent {
  final String id;
  final String title;
  final String description;
  final Map<String, dynamic> requirements;
  final Map<String, dynamic> effects;
  final List<Choice>? choices;

  GameEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.requirements,
    required this.effects,
    this.choices,
  });
}

class EventSystem {
  final Map<String, GameEvent> events = {
    'stranger': GameEvent(
      id: 'stranger',
      title: '陌生人',
      description: '一个陌生人出现在门外。',
      requirements: {
        'buildings': {'hut': 1},
      },
      effects: {},
      choices: [
        Choice(
          text: '欢迎',
          effects: {
            'population': 1,
            'happiness': 5,
          },
        ),
        Choice(
          text: '赶走',
          effects: {
            'happiness': -5,
          },
        ),
      ],
    ),
    'trader': GameEvent(
      id: 'trader',
      title: '商人',
      description: '一个商人想要交易。',
      requirements: {
        'buildings': {'trading_post': 1},
      },
      effects: {},
      choices: [
        Choice(
          text: '交易',
          effects: {
            'trade_available': true,
          },
        ),
        Choice(
          text: '拒绝',
          effects: {},
        ),
      ],
    ),
    'storm': GameEvent(
      id: 'storm',
      title: '暴风雨',
      description: '一场暴风雨正在接近。',
      requirements: {
        'outside_unlocked': true,
      },
      effects: {
        'wood': -10,
        'happiness': -10,
      },
      choices: null,
    ),
  };

  final Random _random = Random();

  // 检查事件是否可以触发
  bool canTrigger(GameEvent event, GameState state) {
    if (event.requirements.containsKey('buildings')) {
      Map<String, int> requiredBuildings =
          Map<String, int>.from(event.requirements['buildings']);
      for (var entry in requiredBuildings.entries) {
        if ((state.room['buildings']?[entry.key] ?? 0) < entry.value) {
          return false;
        }
      }
    }

    if (event.requirements.containsKey('outside_unlocked')) {
      if (!state.outsideUnlocked) return false;
    }

    return true;
  }

  // 检查选项是否可用
  bool canChoose(Choice choice, GameState state) {
    if (choice.requirements == null) return true;

    // 检查资源需求
    if (choice.requirements!.containsKey('resources')) {
      Map<String, int> resources =
          Map<String, int>.from(choice.requirements!['resources']);
      for (var entry in resources.entries) {
        if ((state.resources[entry.key] ?? 0) < entry.value) {
          return false;
        }
      }
    }

    return true;
  }

  // 应用事件效果
  void applyEventEffects(Map<String, dynamic> effects, GameState state) {
    effects.forEach((key, value) {
      switch (key) {
        case 'population':
          state.population['total'] =
              (state.population['total'] as int) + (value as int);
          break;
        case 'happiness':
          state.population['happiness'] =
              (state.population['happiness'] as double) + (value as num);
          break;
        case 'trade_available':
          state.storeOpened = value as bool;
          break;
        default:
          if (state.resources.containsKey(key)) {
            state.addResource(key, value as int);
          }
      }
    });
  }

  // 随机选择一个可触发的事件
  GameEvent? getRandomEvent(GameState state) {
    List<GameEvent> availableEvents =
        events.values.where((event) => canTrigger(event, state)).toList();

    if (availableEvents.isEmpty) return null;

    int randomIndex = _random.nextInt(availableEvents.length);
    return availableEvents[randomIndex];
  }
}
