import 'dart:math';
import 'game_state.dart';
import 'dart:async';
import '../config/game_settings.dart';

class CraftingRecipe {
  final String id;
  final String name;
  final String description;
  final Map<String, int> ingredients;
  final Map<String, int> outputs;
  final int craftingTime;
  final Map<String, dynamic>? requirements;

  CraftingRecipe({
    required this.id,
    required this.name,
    required this.description,
    required this.ingredients,
    required this.outputs,
    required this.craftingTime,
    this.requirements,
  });

  factory CraftingRecipe.fromJson(Map<String, dynamic> json) {
    return CraftingRecipe(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      ingredients: Map<String, int>.from(json['ingredients']),
      outputs: Map<String, int>.from(json['outputs']),
      craftingTime: json['craftingTime'] as int,
      requirements: json['requirements'] != null
          ? Map<String, dynamic>.from(json['requirements'])
          : null,
    );
  }
}

class CraftingSystem {
  final Map<String, CraftingRecipe> recipes =
      GameSettings.craftingRecipeConfigs.map(
    (key, value) => MapEntry(key, CraftingRecipe.fromJson(value)),
  );

  // 添加制作进度追踪
  Map<String, DateTime> _activeCrafting = {};
  Map<String, Timer> _craftingTimers = {};

  // 检查是否可以制作
  bool canCraft(CraftingRecipe recipe, GameState state) {
    // 检查建筑要求
    if (recipe.requirements != null &&
        recipe.requirements!.containsKey('buildings')) {
      Map<String, int> requiredBuildings =
          Map<String, int>.from(recipe.requirements!['buildings']);
      for (var entry in requiredBuildings.entries) {
        if ((state.room['buildings']?[entry.key] ?? 0) < entry.value) {
          return false;
        }
      }
    }

    // 检查材料
    for (var entry in recipe.ingredients.entries) {
      if ((state.resources[entry.key] ?? 0) < entry.value) {
        return false;
      }
    }

    // 检查输出空间
    for (var entry in recipe.outputs.entries) {
      int currentAmount = state.resources[entry.key] ?? 0;
      int limit = state.calculateResourceLimit(entry.key);
      if (currentAmount + entry.value > limit) {
        return false;
      }
    }

    return true;
  }

  // 检查是否正在制作
  bool isCrafting(String recipeId) {
    return _activeCrafting.containsKey(recipeId);
  }

  // 获取制作进度
  double getCraftingProgress(String recipeId) {
    if (!isCrafting(recipeId)) return 0.0;

    final recipe = recipes[recipeId];
    if (recipe == null) return 0.0;

    final startTime = _activeCrafting[recipeId]!;
    final elapsed = DateTime.now().difference(startTime).inMinutes;
    final progress = elapsed / recipe.craftingTime;

    return progress.clamp(0.0, 1.0);
  }

  // 开始制作
  bool startCrafting(String recipeId, GameState state) {
    CraftingRecipe? recipe = recipes[recipeId];
    if (recipe == null || !canCraft(recipe, state) || isCrafting(recipeId)) {
      return false;
    }

    // 消耗材料
    recipe.ingredients.forEach((resource, amount) {
      state.useResource(resource, amount);
    });

    // 记录开始时间
    _activeCrafting[recipeId] = DateTime.now();

    // 设置定时器
    _craftingTimers[recipeId] = Timer(
      Duration(minutes: recipe.craftingTime),
      () {
        completeCrafting(recipeId, state);
      },
    );

    return true;
  }

  // 完成制作
  void completeCrafting(String recipeId, GameState state) {
    final recipe = recipes[recipeId];
    if (recipe == null) return;

    // 添加输出物品
    recipe.outputs.forEach((resource, amount) {
      state.addResource(resource, amount);
    });

    // 清理状态
    _activeCrafting.remove(recipeId);
    _craftingTimers[recipeId]?.cancel();
    _craftingTimers.remove(recipeId);
  }

  // 取消制作
  void cancelCrafting(String recipeId) {
    _craftingTimers[recipeId]?.cancel();
    _craftingTimers.remove(recipeId);
    _activeCrafting.remove(recipeId);
  }

  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'recipes': recipes.map((key, value) => MapEntry(key, {
            'id': value.id,
            'name': value.name,
            'description': value.description,
            'ingredients': value.ingredients,
            'outputs': value.outputs,
            'craftingTime': value.craftingTime,
            'requirements': value.requirements,
          })),
      'activeCrafting': _activeCrafting.map(
        (key, value) => MapEntry(key, value.toIso8601String()),
      ),
    };
  }

  // 从JSON加载
  void fromJson(Map<String, dynamic> json) {
    // 清理现有状态
    _activeCrafting.clear();
    _craftingTimers.values.forEach((timer) => timer.cancel());
    _craftingTimers.clear();

    // 恢复制作状态
    if (json.containsKey('activeCrafting')) {
      final activeCrafting = json['activeCrafting'] as Map<String, dynamic>;
      activeCrafting.forEach((key, value) {
        _activeCrafting[key] = DateTime.parse(value);
      });
    }
  }

  // 清理资源
  void dispose() {
    _craftingTimers.values.forEach((timer) => timer.cancel());
    _craftingTimers.clear();
    _activeCrafting.clear();
  }
}
