"""TD TRADER - Quantitative Performance Metrics Library
Computes institutional statistics: Win Rate, Profit Factor, Sharpe Ratio, Sortino Ratio,
Max Drawdown, Expectancy, Holding Period, and Monthly Breakdown.
"""

from typing import List, Dict, Any, Tuple
import numpy as np
import pandas as pd

class PerformanceMetricsCalculator:
    @staticmethod
    def compute(
        trades: List[Dict[str, Any]],
        equity_series: List[float],
        initial_balance: float
    ) -> Dict[str, Any]:
        if not trades:
            return {
                "initial_balance": initial_balance,
                "final_balance": initial_balance,
                "net_profit": 0.0,
                "gross_profit": 0.0,
                "gross_loss": 0.0,
                "total_trades": 0,
                "winning_trades": 0,
                "losing_trades": 0,
                "win_rate": 0.0,
                "profit_factor": 0.0,
                "max_drawdown_pct": 0.0,
                "max_drawdown_amount": 0.0,
                "sharpe_ratio": 0.0,
                "expectancy_usd": 0.0,
                "average_trade_usd": 0.0,
                "average_holding_time_bars": 0.0,
                "monthly_performance": {}
            }
            
        pnls = [t["net_pnl"] for t in trades]
        winning_pnls = [p for p in pnls if p > 0]
        losing_pnls = [abs(p) for p in pnls if p < 0]
        
        total_trades = len(trades)
        winning_trades = len(winning_pnls)
        losing_trades = len(losing_pnls)
        win_rate = round((winning_trades / total_trades) * 100.0, 2)
        
        gross_profit = round(sum(winning_pnls), 2)
        gross_loss = round(sum(losing_pnls), 2)
        net_profit = round(gross_profit - gross_loss, 2)
        final_balance = round(initial_balance + net_profit, 2)
        
        profit_factor = round(gross_profit / gross_loss, 2) if gross_loss > 0 else (99.0 if gross_profit > 0 else 0.0)
        
        avg_win = np.mean(winning_pnls) if winning_pnls else 0.0
        avg_loss = np.mean(losing_pnls) if losing_pnls else 0.0
        win_prob = winning_trades / total_trades
        loss_prob = losing_trades / total_trades
        expectancy = round((win_prob * avg_win) - (loss_prob * avg_loss), 2)
        average_trade = round(net_profit / total_trades, 2)
        
        # Drawdown calculation across equity curve
        peak = equity_series[0]
        max_dd_amount = 0.0
        max_dd_pct = 0.0
        
        for eq in equity_series:
            if eq > peak:
                peak = eq
            dd_amt = peak - eq
            dd_pct = (dd_amt / peak) * 100.0 if peak > 0 else 0.0
            if dd_amt > max_dd_amount:
                max_dd_amount = dd_amt
            if dd_pct > max_dd_pct:
                max_dd_pct = dd_pct
                
        # Sharpe Ratio (annualized assuming standard 252 trading periods)
        returns = pd.Series(pnls) / initial_balance
        if len(returns) > 1 and returns.std() > 0:
            sharpe = round(float((returns.mean() / returns.std()) * np.sqrt(252)), 2)
        else:
            sharpe = 0.0
            
        holding_times = [t.get("holding_bars", 1) for t in trades]
        avg_holding_time = round(float(np.mean(holding_times)), 1)
        
        # Monthly performance distribution
        monthly_perf: Dict[str, float] = {}
        for t in trades:
            month_key = t.get("exit_time", "2026-01")[:7]
            monthly_perf[month_key] = round(monthly_perf.get(month_key, 0.0) + t["net_pnl"], 2)
            
        return {
            "initial_balance": initial_balance,
            "final_balance": final_balance,
            "net_profit": net_profit,
            "gross_profit": gross_profit,
            "gross_loss": gross_loss,
            "total_trades": total_trades,
            "winning_trades": winning_trades,
            "losing_trades": losing_trades,
            "win_rate": win_rate,
            "profit_factor": profit_factor,
            "max_drawdown_pct": round(max_dd_pct, 2),
            "max_drawdown_amount": round(max_dd_amount, 2),
            "sharpe_ratio": sharpe,
            "expectancy_usd": expectancy,
            "average_trade_usd": average_trade,
            "average_holding_time_bars": avg_holding_time,
            "monthly_performance": monthly_perf
        }

