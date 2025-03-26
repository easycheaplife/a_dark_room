import 'dart:math';

class TradeItem {
  final String resourceId;
  final String name;
  final int basePrice;
  final double priceVariation; // 价格波动范围
  final int maxAmount; // 最大交易数量

  TradeItem({
    required this.resourceId,
    required this.name,
    required this.basePrice,
    this.priceVariation = 0.2,
    this.maxAmount = 100,
  });
}

class TradeSystem {
  final Map<String, TradeItem> tradeItems = {
    'fur': TradeItem(
      resourceId: 'fur',
      name: '毛皮',
      basePrice: 10,
      priceVariation: 0.3,
      maxAmount: 100,
    ),
    'leather': TradeItem(
      resourceId: 'leather',
      name: '皮革',
      basePrice: 15,
      priceVariation: 0.25,
      maxAmount: 100,
    ),
    'iron': TradeItem(
      resourceId: 'iron',
      name: '铁',
      basePrice: 20,
      priceVariation: 0.2,
      maxAmount: 50,
    ),
    'steel': TradeItem(
      resourceId: 'steel',
      name: '钢',
      basePrice: 40,
      priceVariation: 0.15,
      maxAmount: 30,
    ),
    'cloth': TradeItem(
      resourceId: 'cloth',
      name: '布料',
      basePrice: 8,
      priceVariation: 0.35,
      maxAmount: 150,
    ),
  };

  Map<String, int> currentPrices = {};
  DateTime lastPriceUpdate = DateTime.now();
  Map<String, List<double>> priceHistory = {};
  List<Map<String, dynamic>> tradeHistory = [];

  // 更新价格
  void updatePrices() {
    final now = DateTime.now();
    if (now.difference(lastPriceUpdate).inMinutes < 5) return; // 5分钟更新一次

    tradeItems.forEach((id, item) {
      double variation = (Random().nextDouble() * 2 - 1) * item.priceVariation;
      int newPrice = (item.basePrice * (1 + variation)).round();
      currentPrices[id] = newPrice;
    });

    lastPriceUpdate = now;
  }

  // 计算购买价格
  int calculateBuyPrice(String itemId, int amount) {
    updatePrices();
    return (currentPrices[itemId] ?? tradeItems[itemId]!.basePrice) * amount;
  }

  // 计算出售价格
  int calculateSellPrice(String itemId, int amount) {
    updatePrices();
    return ((currentPrices[itemId] ?? tradeItems[itemId]!.basePrice) *
            0.7 *
            amount)
        .round();
  }

  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'lastPriceUpdate': lastPriceUpdate.toIso8601String(),
      'priceHistory': priceHistory,
      'tradeHistory': tradeHistory,
    };
  }

  // 从JSON加载
  void fromJson(Map<String, dynamic> json) {
    lastPriceUpdate = DateTime.parse(json['lastPriceUpdate']);
    priceHistory = Map<String, List<double>>.from(json['priceHistory']);
    tradeHistory = List<Map<String, dynamic>>.from(json['tradeHistory']);
  }
}
