import 'dart:math';
import 'game_state.dart';
import 'dart:async';

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
}

class CraftingSystem {
  final Map<String, CraftingRecipe> recipes = {
    'cured_meat': CraftingRecipe(
      id: 'cured_meat',
      name: '熏肉',
      description: '将生肉制成可以长期保存的熏肉',
      ingredients: {
        'meat': 2,
        'wood': 1,
      },
      outputs: {
        'cured meat': 1,
      },
      craftingTime: 30,
      requirements: {
        'buildings': {'smokehouse': 1},
      },
    ),
    'leather': CraftingRecipe(
      id: 'leather',
      name: '皮革',
      description: '将毛皮加工成皮革',
      ingredients: {
        'fur': 2,
        'water': 1,
      },
      outputs: {
        'leather': 1,
      },
      craftingTime: 20,
      requirements: {
        'buildings': {'tannery': 1},
      },
    ),
    'steel': CraftingRecipe(
      id: 'steel',
      name: '钢',
      description: '将铁和煤炼制成钢',
      ingredients: {
        'iron': 2,
        'coal': 1,
      },
      outputs: {
        'steel': 1,
      },
      craftingTime: 40,
      requirements: {
        'buildings': {'steelworks': 1},
      },
    ),
    'cloth': CraftingRecipe(
      id: 'cloth',
      name: '布料',
      description: '将毛皮制成布料',
      ingredients: {
        'fur': 3,
        'water': 2,
      },
      outputs: {
        'cloth': 1,
      },
      craftingTime: 25,
      requirements: {
        'buildings': {'workshop': 1},
      },
    ),
    'rope': CraftingRecipe(
      id: 'rope',
      name: '绳索',
      description: '用布料制作结实的绳索',
      ingredients: {
        'cloth': 2,
        'leather': 1,
      },
      outputs: {
        'rope': 1,
      },
      craftingTime: 15,
      requirements: {
        'buildings': {'workshop': 1},
      },
    ),
    'medicine': CraftingRecipe(
      id: 'medicine',
      name: '药品',
      description: '用草药制作治疗药品',
      ingredients: {
        'herbs': 3,
        'water': 1,
      },
      outputs: {
        'medicine': 1,
      },
      craftingTime: 20,
      requirements: {
        'buildings': {'workshop': 1},
      },
    ),
    'sword': CraftingRecipe(
      id: 'sword',
      name: '剑',
      description: '制作一把锋利的剑',
      ingredients: {
        'steel': 2,
        'wood': 1,
        'leather': 1,
      },
      outputs: {
        'sword': 1,
      },
      craftingTime: 45,
      requirements: {
        'buildings': {'workshop': 1},
      },
    ),
    'armor': CraftingRecipe(
      id: 'armor',
      name: '盔甲',
      description: '制作一套防护盔甲',
      ingredients: {
        'steel': 3,
        'leather': 2,
        'cloth': 1,
      },
      outputs: {
        'armor': 1,
      },
      craftingTime: 60,
      requirements: {
        'buildings': {'workshop': 1},
      },
    ),
    'gunpowder': CraftingRecipe(
      id: 'gunpowder',
      name: '火药',
      description: '制作火药',
      ingredients: {
        'sulphur': 2,
        'coal': 1,
      },
      outputs: {
        'gunpowder': 1,
      },
      craftingTime: 30,
      requirements: {
        'buildings': {'workshop': 1},
      },
    ),
    'bullet': CraftingRecipe(
      id: 'bullet',
      name: '子弹',
      description: '制作子弹',
      ingredients: {
        'steel': 1,
        'gunpowder': 1,
      },
      outputs: {
        'bullet': 5,
      },
      craftingTime: 20,
      requirements: {
        'buildings': {'workshop': 1},
      },
    ),
    'gun': CraftingRecipe(
      id: 'gun',
      name: '枪',
      description: '制作一把枪',
      ingredients: {
        'steel': 3,
        'wood': 2,
        'gunpowder': 1,
      },
      outputs: {
        'gun': 1,
      },
      craftingTime: 75,
      requirements: {
        'buildings': {'workshop': 1},
      },
    ),
  };

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
