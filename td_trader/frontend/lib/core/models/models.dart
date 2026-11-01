// TD TRADER - Unified Frontend Data Models

class ScoreBreakdown {
  final double trendAlignment;
  final double technicalConfirmation;
  final double momentum;
  final double marketStructure;
  final double volatility;
  final double riskReward;
  final double strategyValidation;
  final double totalScore;

  ScoreBreakdown({
    required this.trendAlignment,
    required this.technicalConfirmation,
    required this.momentum,
    required this.marketStructure,
    required this.volatility,
    required this.riskReward,
    required this.strategyValidation,
    required this.totalScore,
  });

  factory ScoreBreakdown.fromJson(Map<String, dynamic> json) {
    return ScoreBreakdown(
      trendAlignment: (json['trend_alignment'] as num).toDouble(),
      technicalConfirmation: (json['technical_confirmation'] as num).toDouble(),
      momentum: (json['momentum'] as num).toDouble(),
      marketStructure: (json['market_structure'] as num).toDouble(),
      volatility: (json['volatility'] as num).toDouble(),
      riskReward: (json['risk_reward'] as num).toDouble(),
      strategyValidation: (json['strategy_validation'] as num).toDouble(),
      totalScore: (json['total_score'] as num).toDouble(),
    );
  }
}

class SignalModel {
  final int id;
  final String instrument;
  final String marketCategory;
  final String direction;
  final String timeframe;
  final double entryPrice;
  final double stopLoss;
  final double takeProfit1;
  final double? takeProfit2;
  final double riskRewardRatio;
  final double score;
  final ScoreBreakdown scoreBreakdown;
  final String strategyName;
  final String marketStructure;
  final String status;
  final String aiRationale;
  final DateTime createdAt;
  final bool isRealTime;
  final int dataDelaySeconds;

  SignalModel({
    required this.id,
    required this.instrument,
    required this.marketCategory,
    required this.direction,
    required this.timeframe,
    required this.entryPrice,
    required this.stopLoss,
    required this.takeProfit1,
    this.takeProfit2,
    required this.riskRewardRatio,
    required this.score,
    required this.scoreBreakdown,
    required this.strategyName,
    required this.marketStructure,
    required this.status,
    required this.aiRationale,
    required this.createdAt,
    required this.isRealTime,
    required this.dataDelaySeconds,
  });

  factory SignalModel.fromJson(Map<String, dynamic> json) {
    return SignalModel(
      id: json['id'],
      instrument: json['instrument'],
      marketCategory: json['market_category'],
      direction: json['direction'],
      timeframe: json['timeframe'],
      entryPrice: (json['entry_price'] as num).toDouble(),
      stopLoss: (json['stop_loss'] as num).toDouble(),
      takeProfit1: (json['take_profit_1'] as num).toDouble(),
      takeProfit2: json['take_profit_2'] != null ? (json['take_profit_2'] as num).toDouble() : null,
      riskRewardRatio: (json['risk_reward_ratio'] as num).toDouble(),
      score: (json['score'] as num).toDouble(),
      scoreBreakdown: ScoreBreakdown.fromJson(json['score_breakdown']),
      strategyName: json['strategy_name'],
      marketStructure: json['market_structure'],
      status: json['status'],
      aiRationale: json['ai_rationale'],
      createdAt: DateTime.parse(json['created_at']),
      isRealTime: json['is_real_time'] ?? true,
      dataDelaySeconds: json['data_delay_seconds'] ?? 0,
    );
  }
}

class TradingAccountModel {
  final int id;
  final String accountNumber;
  final String brokerName;
  final String server;
  final String platform;
  final String currency;
  final double balance;
  final double equity;
  final double freeMargin;
  final double usedMargin;
  final double floatingPnl;
  final String connectionStatus;
  final bool isAutoTradingEnabled;
  final bool isAuthorizedLive;

  TradingAccountModel({
    required this.id,
    required this.accountNumber,
    required this.brokerName,
    required this.server,
    required this.platform,
    required this.currency,
    required this.balance,
    required this.equity,
    required this.freeMargin,
    required this.usedMargin,
    required this.floatingPnl,
    required this.connectionStatus,
    required this.isAutoTradingEnabled,
    required this.isAuthorizedLive,
  });

  factory TradingAccountModel.fromJson(Map<String, dynamic> json) {
    return TradingAccountModel(
      id: json['id'],
      accountNumber: json['account_number'],
      brokerName: json['broker_name'],
      server: json['server'],
      platform: json['platform'],
      currency: json['currency'],
      balance: (json['balance'] as num).toDouble(),
      equity: (json['equity'] as num).toDouble(),
      freeMargin: (json['free_margin'] as num).toDouble(),
      usedMargin: (json['used_margin'] as num).toDouble(),
      floatingPnl: (json['floating_pnl'] as num).toDouble(),
      connectionStatus: json['connection_status'],
      isAutoTradingEnabled: json['is_auto_trading_enabled'] ?? false,
      isAuthorizedLive: json['is_authorized_live'] ?? false,
    );
  }
}

class RiskConfigModel {
  final int id;
  final int accountId;
  final double riskPerTradePct;
  final double maxDailyLossPct;
  final double maxDailyLossAmount;
  final double maxDailyDrawdownPct;
  final double maxAccountDrawdownPct;
  final int maxOpenTrades;
  final int maxCorrelatedExposure;
  final double maxLotSize;
  final int consecutiveLossLimit;
  final int currentConsecutiveLosses;
  final double currentDailyLoss;
  final bool isRiskGuardianTripped;
  final String? tripReason;
  final bool autoLiquidateOnBreach;
  final bool emergencyPaused;

  RiskConfigModel({
    required this.id,
    required this.accountId,
    required this.riskPerTradePct,
    required this.maxDailyLossPct,
    required this.maxDailyLossAmount,
    required this.maxDailyDrawdownPct,
    required this.maxAccountDrawdownPct,
    required this.maxOpenTrades,
    required this.maxCorrelatedExposure,
    required this.maxLotSize,
    required this.consecutiveLossLimit,
    required this.currentConsecutiveLosses,
    required this.currentDailyLoss,
    required this.isRiskGuardianTripped,
    this.tripReason,
    required this.autoLiquidateOnBreach,
    required this.emergencyPaused,
  });

  factory RiskConfigModel.fromJson(Map<String, dynamic> json) {
    return RiskConfigModel(
      id: json['id'],
      accountId: json['account_id'],
      riskPerTradePct: (json['risk_per_trade_pct'] as num).toDouble(),
      maxDailyLossPct: (json['max_daily_loss_pct'] as num).toDouble(),
      maxDailyLossAmount: (json['max_daily_loss_amount'] as num).toDouble(),
      maxDailyDrawdownPct: (json['max_daily_drawdown_pct'] as num).toDouble(),
      maxAccountDrawdownPct: (json['max_account_drawdown_pct'] as num).toDouble(),
      maxOpenTrades: json['max_open_trades'],
      maxCorrelatedExposure: json['max_correlated_exposure'],
      maxLotSize: (json['max_lot_size'] as num).toDouble(),
      consecutiveLossLimit: json['consecutive_loss_limit'],
      currentConsecutiveLosses: json['current_consecutive_losses'],
      currentDailyLoss: (json['current_daily_loss'] as num).toDouble(),
      isRiskGuardianTripped: json['is_risk_guardian_tripped'],
      tripReason: json['trip_reason'],
      autoLiquidateOnBreach: json['auto_liquidate_on_breach'],
      emergencyPaused: json['emergency_paused'],
    );
  }
}

class PositionModel {
  final int id;
  final String positionTicket;
  final String instrument;
  final String direction;
  final double lots;
  final double openPrice;
  final double currentPrice;
  final double? stopLoss;
  final double? takeProfit;
  final double floatingPnl;
  final String openTime;

  PositionModel({
    required this.id,
    required this.positionTicket,
    required this.instrument,
    required this.direction,
    required this.lots,
    required this.openPrice,
    required this.currentPrice,
    this.stopLoss,
    this.takeProfit,
    required this.floatingPnl,
    required this.openTime,
  });

  factory PositionModel.fromJson(Map<String, dynamic> json) {
    return PositionModel(
      id: json['id'],
      positionTicket: json['position_ticket'],
      instrument: json['instrument'],
      direction: json['direction'],
      lots: (json['lots'] as num).toDouble(),
      openPrice: (json['open_price'] as num).toDouble(),
      currentPrice: (json['current_price'] as num).toDouble(),
      stopLoss: json['stop_loss'] != null ? (json['stop_loss'] as num).toDouble() : null,
      takeProfit: json['take_profit'] != null ? (json['take_profit'] as num).toDouble() : null,
      floatingPnl: (json['floating_pnl'] as num).toDouble(),
      openTime: json['open_time'],
    );
  }
}

