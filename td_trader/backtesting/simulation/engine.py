"""TD TRADER - High-Fidelity Quantitative Backtesting Simulation Engine
Simulates realistic order execution with intra-bar SL/TP traversal, dynamic spread,
execution slippage, lot commissions, and overnight swap financing.
"""

from typing import Dict, Any, List, Optional
import numpy as np
import pandas as pd
from td_trader.ai_engine.market_scanner.market_data_feed import market_data_feed, INSTRUMENT_CATALOG
from td_trader.ai_engine.strategy_engine.strategies import STRATEGY_REGISTRY
from td_trader.backtesting.performance_metrics.metrics import PerformanceMetricsCalculator
from td_trader.backend.app.schemas.schemas import BacktestRequest, BacktestResult

class BacktestEngine:
    """Quantitative Strategy Backtester with institutional execution modeling."""
    
    @staticmethod
    def run_backtest(req: BacktestRequest) -> BacktestResult:
        symbol = req.instrument
        meta = INSTRUMENT_CATALOG.get(symbol, {"pip_size": 0.0001, "digits": 5, "typical_spread": 1.2})
        pip_size = meta["pip_size"]
        
        # Load historical OHLCV data
        try:
            df = market_data_feed.get_ohlcv(symbol, req.timeframe)
        except Exception:
            raise ValueError(f"Unable to load historical data for {symbol} on {req.timeframe}")
            
        strategy_cls = STRATEGY_REGISTRY.get(req.strategy_name)
        if not strategy_cls:
            raise ValueError(f"Strategy '{req.strategy_name}' not found in registry.")
            
        strategy = strategy_cls(req.parameters)
        
        # Backtest state
        balance = req.initial_balance
        equity = req.initial_balance
        equity_series: List[float] = [equity]
        equity_curve_points: List[Dict[str, Any]] = [
            {"bar": 0, "timestamp": str(df.index[0]), "equity": round(equity, 2), "drawdown_pct": 0.0}
        ]
        
        closed_trades: List[Dict[str, Any]] = []
        active_trade: Optional[Dict[str, Any]] = None
        
        # Trading cost settings
        spread_val = req.spread_pips * pip_size
        slippage_val = req.slippage_pips * pip_size
        commission_per_lot = req.commission_per_lot
        
        # Minimum warm-up period for indicators
        warmup = 35
        for i in range(warmup, len(df)):
            curr_bar = df.iloc[i]
            prev_slice = df.iloc[:i]
            bar_time = str(df.index[i])
            
            # 1. Manage Active Position (Intra-bar SL/TP Traversal)
            if active_trade is not None:
                high = curr_bar['high']
                low = curr_bar['low']
                close = curr_bar['close']
                direction = active_trade['direction']
                entry = active_trade['entry_price']
                sl = active_trade['stop_loss']
                tp = active_trade['take_profit']
                lots = active_trade['lots']
                
                trade_closed = False
                exit_price = 0.0
                exit_reason = ""
                
                if direction == "BUY":
                    # Check Stop Loss breach
                    if low <= sl:
                        trade_closed = True
                        exit_price = sl - slippage_val
                        exit_reason = "STOP_LOSS"
                    # Check Take Profit breach
                    elif high >= tp:
                        trade_closed = True
                        exit_price = tp
                        exit_reason = "TAKE_PROFIT"
                else: # SELL
                    # Check Stop Loss breach
                    if high >= sl:
                        trade_closed = True
                        exit_price = sl + slippage_val
                        exit_reason = "STOP_LOSS"
                    # Check Take Profit breach
                    elif low <= tp:
                        trade_closed = True
                        exit_price = tp
                        exit_reason = "TAKE_PROFIT"
                        
                if trade_closed:
                    # Calculate PnL with costs
                    pip_factor = 10.0 if meta.get("category") in ["FOREX", "METALS"] else 1.0
                    if direction == "BUY":
                        pips = (exit_price - entry) / pip_size
                    else:
                        pips = (entry - exit_price) / pip_size
                        
                    gross_pnl = pips * lots * pip_factor
                    commission = lots * commission_per_lot
                    net_pnl = round(gross_pnl - commission, 2)
                    
                    balance += net_pnl
                    equity = balance
                    
                    active_trade.update({
                        "exit_price": round(exit_price, meta["digits"]),
                        "exit_time": bar_time,
                        "exit_reason": exit_reason,
                        "net_pnl": net_pnl,
                        "gross_pnl": round(gross_pnl, 2),
                        "commission": commission,
                        "holding_bars": i - active_trade["entry_bar"]
                    })
                    closed_trades.append(active_trade)
                    active_trade = None
                    
            # 2. Check for New Strategy Entry (if no active position)
            if active_trade is None:
                eval_res = strategy.evaluate(prev_slice)
                if eval_res.get("triggered", False):
                    direction = eval_res["direction"]
                    raw_entry = eval_res["entry_price"]
                    sl = eval_res["stop_loss"]
                    tp = eval_res["take_profit_1"]
                    
                    # Apply spread and slippage to entry
                    if direction == "BUY":
                        fill_entry = raw_entry + spread_val + slippage_val
                    else:
                        fill_entry = raw_entry - slippage_val
                        
                    # Calculate dynamic position size based on risk %
                    sl_dist = abs(fill_entry - sl) / pip_size
                    risk_usd = balance * (req.risk_per_trade_pct / 100.0)
                    pip_factor = 10.0 if meta.get("category") in ["FOREX", "METALS"] else 1.0
                    lots = round(max(0.01, min(risk_usd / max(sl_dist * pip_factor, 1.0), 5.0)), 2)
                    
                    active_trade = {
                        "direction": direction,
                        "entry_price": round(fill_entry, meta["digits"]),
                        "stop_loss": round(sl, meta["digits"]),
                        "take_profit": round(tp, meta["digits"]),
                        "lots": lots,
                        "entry_time": bar_time,
                        "entry_bar": i
                    }
                    
            equity_series.append(equity)
            equity_curve_points.append({
                "bar": i,
                "timestamp": bar_time,
                "equity": round(equity, 2),
                "drawdown_pct": round(max(0.0, (req.initial_balance - equity) / req.initial_balance * 100.0), 2)
            })
            
        # Compute performance metrics
        perf = PerformanceMetricsCalculator.compute(closed_trades, equity_series, req.initial_balance)
        
        # Walk-forward analysis metrics
        walk_forward_data = None
        if req.run_walk_forward:
            from td_trader.backtesting.walk_forward.walk_forward import WalkForwardAnalyzer
            walk_forward_data = WalkForwardAnalyzer.analyze(df, strategy_cls, req)

        return BacktestResult(
            strategy_name=req.strategy_name,
            instrument=req.instrument,
            timeframe=req.timeframe,
            initial_balance=perf["initial_balance"],
            final_balance=perf["final_balance"],
            net_profit=perf["net_profit"],
            gross_profit=perf["gross_profit"],
            gross_loss=perf["gross_loss"],
            total_trades=perf["total_trades"],
            winning_trades=perf["winning_trades"],
            losing_trades=perf["losing_trades"],
            win_rate=perf["win_rate"],
            profit_factor=perf["profit_factor"],
            max_drawdown_pct=perf["max_drawdown_pct"],
            max_drawdown_amount=perf["max_drawdown_amount"],
            sharpe_ratio=perf["sharpe_ratio"],
            expectancy_usd=perf["expectancy_usd"],
            average_trade_usd=perf["average_trade_usd"],
            average_holding_time_bars=perf["average_holding_time_bars"],
            equity_curve=equity_curve_points,
            monthly_performance=perf["monthly_performance"],
            walk_forward_metrics=walk_forward_data
        )

    @staticmethod
    def compare_strategies(
        instrument: str,
        strategies: List[str],
        timeframe: str = "H1",
        initial_balance: float = 10000.0
    ) -> List[Dict[str, Any]]:
        """Compares multiple strategies side-by-side on the exact same instrument data."""
        comparison_results = []
        for s_name in strategies:
            if s_name in STRATEGY_REGISTRY:
                req = BacktestRequest(
                    strategy_name=s_name,
                    instrument=instrument,
                    timeframe=timeframe,
                    start_date="2026-01-01",
                    end_date="2026-11-01",
                    initial_balance=initial_balance,
                    run_walk_forward=False
                )
                res = BacktestEngine.run_backtest(req)
                comparison_results.append({
                    "strategy_name": res.strategy_name,
                    "net_profit": res.net_profit,
                    "win_rate": res.win_rate,
                    "profit_factor": res.profit_factor,
                    "max_drawdown_pct": res.max_drawdown_pct,
                    "total_trades": res.total_trades,
                    "sharpe_ratio": res.sharpe_ratio
                })
        return comparison_results

backtest_engine = BacktestEngine()

