/// 表示一个游戏事件的选择及其效果
class Choice {
  final String id;
  final String text;
  final Map<String, dynamic> effects;

  Choice({
    required this.id,
    required this.text,
    required this.effects,
  });

  factory Choice.fromJson(Map<String, dynamic> json) {
    return Choice(
      id: json['id'] as String,
      text: json['text'] as String,
      effects: json['effects'] as Map<String, dynamic>,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'effects': effects,
    };
  }
}

/// 表示游戏中的一个事件，包含标题、描述和可能的选择
class GameEvent {
  final String id;
  final String title;
  final String description;
  final List<Choice> choices;
  bool resolved = false;

  GameEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.choices,
    this.resolved = false,
  });

  factory GameEvent.fromJson(Map<String, dynamic> json) {
    return GameEvent(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      choices: (json['choices'] as List)
          .map((e) => Choice.fromJson(e as Map<String, dynamic>))
          .toList(),
      resolved: json['resolved'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'choices': choices.map((e) => e.toJson()).toList(),
      'resolved': resolved,
    };
  }
}
