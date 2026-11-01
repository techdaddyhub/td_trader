"""TD TRADER - Algorithmic Strategy Engine
Implements canonical and quantitative strategies with entry/exit rules,
ATR-based dynamic SL/TP calculation, and custom strategy composition.
"""

from typing import Dict, Any, Optional, Tuple
import pandas as pd
import numpy as np
from td_trader.ai_engine.technical_analysis.indicators import TechnicalIndicators
from td_trader.ai_engine.technical_analysis.market_structure import MarketStructureAnalyzer

class BaseStrategy:
    name: str = "BaseStrategy"
    
    def __init__(self, params: Optional[Dict[str, Any]] = None):
        self.params = params or {}
        
    def evaluate(self, df: pd.DataFrame) -> Dict[str, Any]:
        """Evaluates price history and returns signal dictionary if setup triggers."""
        raise NotImplementedError

class MovingAverageCrossoverStrategy(BaseStrategy):
    name = "MA_Crossover"
    
    def evaluate(self, df: pd.DataFrame) -> Dict[str, Any]:
        fast_p = int(self.params.get("fast_period", 9))
        slow_p = int(self.params.get("slow_period", 21))
        
        df = df.copy()
        fast_ema = TechnicalIndicators.calculate_ema(df['close'], fast_p)
        slow_ema = TechnicalIndicators.calculate_ema(df['close'], slow_p)
        atr = TechnicalIndicators.calculate_atr(df, 14)
        
        curr_fast, prev_fast = fast_ema.iloc[-1], fast_ema.iloc[-2]
        curr_slow, prev_slow = slow_ema.iloc[-1], slow_ema.iloc[-2]
        curr_close = df['close'].iloc[-1]
        curr_atr = atr.iloc[-1]
        
        # Bullish Crossover
        if prev_fast <= prev_slow and curr_fast > curr_slow:
            sl = curr_close - (1.5 * curr_atr)
            tp1 = curr_close + (2.5 * curr_atr)
            return {
                "triggered": True,
                "direction": "BUY",
                "strategy": self.name,
                "entry_price": float(curr_close),
                "stop_loss": float(sl),
                "take_profit_1": float(tp1),
                "take_profit_2": float(curr_close + (4.0 * curr_atr)),
                "risk_reward": round((tp1 - curr_close) / (curr_close - sl), 2),
                "rationale": f"Bullish EMA {fast_p} crossed above EMA {slow_p} with supporting ATR expansion."
            }
            
        # Bearish Crossover
        if prev_fast >= prev_slow and curr_fast < curr_slow:
            sl = curr_close + (1.5 * curr_atr)
            tp1 = curr_close - (2.5 * curr_atr)
            return {
                "triggered": True,
                "direction": "SELL",
                "strategy": self.name,
                "entry_price": float(curr_close),
                "stop_loss": float(sl),
                "take_profit_1": float(tp1),
                "take_profit_2": float(curr_close - (4.0 * curr_atr)),
                "risk_reward": round((curr_close - tp1) / (sl - curr_close), 2),
                "rationale": f"Bearish EMA {fast_p} crossed below EMA {slow_p} with momentum breakdown."
            }
            
        return {"triggered": False}

class RSIStrategy(BaseStrategy):
    name = "RSI_Dynamic_Reversal"
    
    def evaluate(self, df: pd.DataFrame) -> Dict[str, Any]:
        period = int(self.params.get("period", 14))
        oversold = float(self.params.get("oversold", 30.0))
        overbought = float(self.params.get("overbought", 70.0))
        
        rsi = TechnicalIndicators.calculate_rsi(df['close'], period)
        atr = TechnicalIndicators.calculate_atr(df, 14)
        curr_close = df['close'].iloc[-1]
        curr_atr = atr.iloc[-1]
        
        curr_rsi, prev_rsi = rsi.iloc[-1], rsi.iloc[-2]
        
        # Oversold Bounce
        if prev_rsi <= oversold and curr_rsi > oversold:
            sl = df['low'].iloc[-5:].min() - (0.5 * curr_atr)
            tp1 = curr_close + (2.0 * curr_atr)
            return {
                "triggered": True,
                "direction": "BUY",
                "strategy": self.name,
                "entry_price": float(curr_close),
                "stop_loss": float(sl),
                "take_profit_1": float(tp1),
                "risk_reward": round((tp1 - curr_close) / max(curr_close - sl, 0.0001), 2),
                "rationale": f"RSI({period}) reclaimed oversold line ({curr_rsi:.1f} > {oversold}), signalling mean-reversion."
            }
            
        # Overbought Rejection
        if prev_rsi >= overbought and curr_rsi < overbought:
            sl = df['high'].iloc[-5:].max() + (0.5 * curr_atr)
            tp1 = curr_close - (2.0 * curr_atr)
            return {
                "triggered": True,
                "direction": "SELL",
                "strategy": self.name,
                "entry_price": float(curr_close),
                "stop_loss": float(sl),
                "take_profit_1": float(tp1),
                "risk_reward": round((curr_close - tp1) / max(sl - curr_close, 0.0001), 2),
                "rationale": f"RSI({period}) rejected from overbought ({curr_rsi:.1f} < {overbought}), signalling exhaustion."
            }
            
        return {"triggered": False}

class MACDTrendStrategy(BaseStrategy):
    name = "MACD_Momentum"
    
    def evaluate(self, df: pd.DataFrame) -> Dict[str, Any]:
        macd, signal, hist = TechnicalIndicators.calculate_macd(df['close'])
        atr = TechnicalIndicators.calculate_atr(df, 14)
        curr_close = df['close'].iloc[-1]
        curr_atr = atr.iloc[-1]
        
        # MACD Line crosses above Signal Line below zero (strong bull momentum turn)
        if hist.iloc[-2] <= 0 and hist.iloc[-1] > 0 and macd.iloc[-1] < 0:
            sl = curr_close - (1.5 * curr_atr)
            tp = curr_close + (3.0 * curr_atr)
            return {
                "triggered": True,
                "direction": "BUY",
                "strategy": self.name,
                "entry_price": float(curr_close),
                "stop_loss": float(sl),
                "take_profit_1": float(tp),
                "risk_reward": round((tp - curr_close) / (curr_close - sl), 2),
                "rationale": "MACD histogram flipped positive while oscillator was below baseline, confirming bullish shift."
            }
            
        # MACD Line crosses below Signal Line above zero (strong bear momentum turn)
        if hist.iloc[-2] >= 0 and hist.iloc[-1] < 0 and macd.iloc[-1] > 0:
            sl = curr_close + (1.5 * curr_atr)
            tp = curr_close - (3.0 * curr_atr)
            return {
                "triggered": True,
                "direction": "SELL",
                "strategy": self.name,
                "entry_price": float(curr_close),
                "stop_loss": float(sl),
                "take_profit_1": float(tp),
                "risk_reward": round((curr_close - tp) / (sl - curr_close), 2),
                "rationale": "MACD histogram flipped negative above baseline, confirming bearish divergence."
            }
            
        return {"triggered": False}

class BollingerBreakoutStrategy(BaseStrategy):
    name = "Bollinger_Squeeze_Breakout"
    
    def evaluate(self, df: pd.DataFrame) -> Dict[str, Any]:
        upper, middle, lower, bandwidth = TechnicalIndicators.calculate_bollinger_bands(df['close'])
        atr = TechnicalIndicators.calculate_atr(df, 14)
        curr_close = df['close'].iloc[-1]
        curr_atr = atr.iloc[-1]
        
        # Look for bandwidth squeeze then breakout
        min_bw_recent = bandwidth.iloc[-15:-1].min()
        curr_bw = bandwidth.iloc[-1]
        
        if curr_bw > min_bw_recent * 1.25: # Band expansion
            if curr_close > upper.iloc[-1]:
                sl = middle.iloc[-1]
                tp = curr_close + (2.0 * (curr_close - sl))
                return {
                    "triggered": True,
                    "direction": "BUY",
                    "strategy": self.name,
                    "entry_price": float(curr_close),
                    "stop_loss": float(sl),
                    "take_profit_1": float(tp),
                    "risk_reward": 2.0,
                    "rationale": "Volatility squeeze expansion breaking through upper Bollinger Band."
                }
            elif curr_close < lower.iloc[-1]:
                sl = middle.iloc[-1]
                tp = curr_close - (2.0 * (sl - curr_close))
                return {
                    "triggered": True,
                    "direction": "SELL",
                    "strategy": self.name,
                    "entry_price": float(curr_close),
                    "stop_loss": float(sl),
                    "take_profit_1": float(tp),
                    "risk_reward": 2.0,
                    "rationale": "Volatility squeeze expansion breaking down through lower Bollinger Band."
                }
                
        return {"triggered": False}

class TrendFollowingStrategy(BaseStrategy):
    name = "Supertrend_Structure_Confluence"
    
    def evaluate(self, df: pd.DataFrame) -> Dict[str, Any]:
        supertrend, direction = TechnicalIndicators.calculate_supertrend(df)
        structure = MarketStructureAnalyzer.detect_market_structure(df)
        sweeps = MarketStructureAnalyzer.detect_liquidity_sweeps(df)
        atr = TechnicalIndicators.calculate_atr(df, 14)
        
        curr_close = df['close'].iloc[-1]
        curr_atr = atr.iloc[-1]
        
        # Bullish confluence: Supertrend bull + Bullish BOS or Bullish trend
        if direction.iloc[-1] == 1 and (structure['trend'] == "BULLISH" or structure.get('last_bos') == "BOS_BULLISH_CONTINUATION"):
            sl = float(supertrend.iloc[-1])
            if curr_close <= sl:
                sl = curr_close - (1.8 * curr_atr)
            tp = curr_close + (2.5 * (curr_close - sl))
            return {
                "triggered": True,
                "direction": "BUY",
                "strategy": self.name,
                "entry_price": float(curr_close),
                "stop_loss": float(sl),
                "take_profit_1": float(tp),
                "risk_reward": round((tp - curr_close) / (curr_close - sl), 2),
                "market_structure": structure.get('last_bos') or "BULLISH_TREND",
                "rationale": "Confluence of bullish Supertrend, higher-high market structure, and buyer momentum."
            }
            
        # Bearish confluence: Supertrend bear + Bearish BOS or Bearish trend
        if direction.iloc[-1] == -1 and (structure['trend'] == "BEARISH" or structure.get('last_bos') == "BOS_BEARISH_CONTINUATION"):
            sl = float(supertrend.iloc[-1])
            if curr_close >= sl:
                sl = curr_close + (1.8 * curr_atr)
            tp = curr_close - (2.5 * (sl - curr_close))
            return {
                "triggered": True,
                "direction": "SELL",
                "strategy": self.name,
                "entry_price": float(curr_close),
                "stop_loss": float(sl),
                "take_profit_1": float(tp),
                "risk_reward": round((curr_close - tp) / (sl - curr_close), 2),
                "market_structure": structure.get('last_bos') or "BEARISH_TREND",
                "rationale": "Confluence of bearish Supertrend, lower-low market structure, and institutional breakdown."
            }
            
        return {"triggered": False}

STRATEGY_REGISTRY = {
    "MA_Crossover": MovingAverageCrossoverStrategy,
    "RSI_Dynamic_Reversal": RSIStrategy,
    "MACD_Momentum": MACDTrendStrategy,
    "Bollinger_Squeeze_Breakout": BollingerBreakoutStrategy,
    "Supertrend_Structure_Confluence": TrendFollowingStrategy
}

