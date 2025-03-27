import 'dart:math';
import 'game_state.dart';
import '../config/game_settings.dart';

class Choice {
  final String text;
  final Map<String, dynamic> effects;
  final Map<String, dynamic>? requirements;

  Choice({
    required this.text,
    required this.effects,
    this.requirements,
  });

  factory Choice.fromJson(Map<String, dynamic> json) {
    return Choice(
      text: json['text'] as String,
      effects: Map<String, dynamic>.from(json['effects']),
      requirements: json['requirements'] != null
          ? Map<String, dynamic>.from(json['requirements'])
          : null,
    );
  }
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

  factory GameEvent.fromJson(Map<String, dynamic> json) {
    return GameEvent(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      requirements: Map<String, dynamic>.from(json['requirements']),
      effects: Map<String, dynamic>.from(json['effects']),
      choices: json['choices'] != null
          ? (json['choices'] as List)
              .map((choice) => Choice.fromJson(choice))
              .toList()
          : null,
    );
  }
}

class EventSystem {
  DateTime lastEventTime = DateTime.now();
  List<String> eventHistory = [];
  Map<String, bool> eventFlags = {};

  final Map<String, GameEvent> events = GameSettings.eventConfigs.map(
    (key, value) => MapEntry(key, GameEvent.fromJson(value)),
  );

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

  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'lastEventTime': lastEventTime.toIso8601String(),
      'eventHistory': eventHistory,
      'eventFlags': eventFlags,
    };
  }

  // 从JSON加载
  void fromJson(Map<String, dynamic> json) {
    lastEventTime = DateTime.parse(json['lastEventTime']);
    eventHistory = List<String>.from(json['eventHistory']);
    eventFlags = Map<String, bool>.from(json['eventFlags']);
  }
}
