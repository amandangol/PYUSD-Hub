class PyusdStats {
  final double totalSupply;
  final double circulatingSupply;
  final double marketCap;
  final double volume24h;
  final double price;
  final List<ChartDataPoint> supplyHistory;
  final List<ChartDataPoint> priceHistory;
  final List<NetworkMetric> networkMetrics;
  final List<TransactionStat> transactionStats;
  final PyusdAdoption adoption;

  PyusdStats({
    required this.totalSupply,
    required this.circulatingSupply,
    required this.marketCap,
    required this.volume24h,
    required this.price,
    required this.supplyHistory,
    required this.priceHistory,
    required this.networkMetrics,
    required this.transactionStats,
    required this.adoption,
  });

  factory PyusdStats.initial() {
    return PyusdStats(
      totalSupply: 0,
      circulatingSupply: 0,
      marketCap: 0,
      volume24h: 0,
      price: 1.0, // As a stablecoin, initial price is 1.0
      supplyHistory: [],
      priceHistory: [],
      networkMetrics: [],
      transactionStats: [],
      adoption: PyusdAdoption.initial(),
    );
  }
}

class ChartDataPoint {
  final DateTime timestamp;
  final double value;

  ChartDataPoint({required this.timestamp, required this.value});
}

class NetworkMetric {
  final String name;
  final double value;
  final String description;
  final String unit;

  NetworkMetric({
    required this.name,
    required this.value,
    required this.description,
    required this.unit,
  });
}

class TransactionStat {
  final DateTime date;
  final int count;
  final double volume;
  final double avgGasPrice;

  TransactionStat({
    required this.date,
    required this.count,
    required this.volume,
    required this.avgGasPrice,
  });
}

class PyusdAdoption {
  final int totalHolders;
  final int activeAddresses24h;
  final List<ChainDistribution> chainDistribution;
  final List<WalletTypeDistribution> walletTypeDistribution;

  PyusdAdoption({
    required this.totalHolders,
    required this.activeAddresses24h,
    required this.chainDistribution,
    required this.walletTypeDistribution,
  });

  factory PyusdAdoption.initial() {
    return PyusdAdoption(
      totalHolders: 0,
      activeAddresses24h: 0,
      chainDistribution: [],
      walletTypeDistribution: [],
    );
  }
}

class ChainDistribution {
  final String chainName;
  final double percentage;
  final double amount;

  ChainDistribution({
    required this.chainName,
    required this.percentage,
    required this.amount,
  });
}

class WalletTypeDistribution {
  final String walletType;
  final double percentage;
  final int count;

  WalletTypeDistribution({
    required this.walletType,
    required this.percentage,
    required this.count,
  });
}
