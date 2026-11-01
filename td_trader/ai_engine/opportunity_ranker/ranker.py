"""TD TRADER - AI Opportunity Ranking Engine
Scores trading opportunities from 0 to 100 with full mathematical transparency across 7 weighted dimensions.
"""

from typing import Dict, Any
from td_trader.backend.app.schemas.schemas import OpportunityScoreBreakdown

class OpportunityRanker:
    """Calculates granular, transparent scores for market opportunities."""
    
    @staticmethod
    def calculate_score(
        trend_aligned: bool,
        trend_strength: float,           # 0.0 to 1.0 (e.g. ADX or EMA slope)
        rsi_value: float,
        macd_histogram: float,
        supertrend_direction: int,
        market_structure: str,           # BOS_BULLISH, CHOCH_BEARISH, etc.
        liquidity_sweep_present: bool,
        supply_demand_confluence: bool,
        atr_ratio: float,                # current ATR / 20-bar avg ATR (volatility health)
        risk_reward_ratio: float,        # e.g. 2.5
        strategy_confirmed: bool,
        direction: str                   # BUY or SELL
    ) -> OpportunityScoreBreakdown:
        
        # 1. Trend Alignment (Max 20 points)
        trend_score = 0.0
        if trend_aligned:
            trend_score = 12.0 + (8.0 * min(max(trend_strength, 0.0), 1.0))
        else:
            # Counter-trend setups get lower trend score unless strong reversal
            trend_score = 4.0 if liquidity_sweep_present else 0.0
            
        # 2. Technical Confirmation (Max 20 points)
        # Supertrend (8 pts), Moving averages (6 pts), Oscillator positioning (6 pts)
        tech_score = 0.0
        if (direction == "BUY" and supertrend_direction == 1) or (direction == "SELL" and supertrend_direction == -1):
            tech_score += 8.0
            
        if direction == "BUY":
            if 40 <= rsi_value <= 65: # Healthy bullish momentum zone
                tech_score += 6.0
            elif rsi_value < 35:      # Oversold bounce
                tech_score += 4.0
            if macd_histogram > 0:
                tech_score += 6.0
        else:
            if 35 <= rsi_value <= 60: # Healthy bearish momentum zone
                tech_score += 6.0
            elif rsi_value > 65:      # Overbought drop
                tech_score += 4.0
            if macd_histogram < 0:
                tech_score += 6.0

        # 3. Momentum (Max 15 points)
        momentum_score = 0.0
        if direction == "BUY":
            if 50 < rsi_value < 70 and macd_histogram > 0:
                momentum_score = 15.0
            elif rsi_value > 45:
                momentum_score = 10.0
            else:
                momentum_score = 5.0
        else:
            if 30 < rsi_value < 50 and macd_histogram < 0:
                momentum_score = 15.0
            elif rsi_value < 55:
                momentum_score = 10.0
            else:
                momentum_score = 5.0

        # 4. Market Structure (Max 15 points)
        # BOS (+8), CHoCH / Reversal Confirmation (+5), Supply/Demand (+4)
        structure_score = 0.0
        if "BOS" in market_structure:
            structure_score += 8.0
        elif "CHOCH" in market_structure:
            structure_score += 6.0
            
        if supply_demand_confluence:
            structure_score += 4.0
        if liquidity_sweep_present:
            structure_score += 3.0
        structure_score = min(structure_score, 15.0)

        # 5. Volatility (Max 10 points)
        # Healthy volatility expansion (ATR ratio between 0.9 and 2.0)
        vol_score = 0.0
        if 1.0 <= atr_ratio <= 1.8:
            vol_score = 10.0 # Prime expansion
        elif 0.8 <= atr_ratio < 1.0 or 1.8 < atr_ratio <= 2.5:
            vol_score = 7.0  # Acceptable
        else:
            vol_score = 3.0  # Choppy consolidation or extreme anomaly

        # 6. Risk / Reward Ratio (Max 10 points)
        # >= 3.0 (10 pts), >= 2.0 (8 pts), >= 1.5 (6 pts), < 1.5 (2 pts)
        rr_score = 0.0
        if risk_reward_ratio >= 3.0:
            rr_score = 10.0
        elif risk_reward_ratio >= 2.0:
            rr_score = 8.0
        elif risk_reward_ratio >= 1.5:
            rr_score = 6.0
        else:
            rr_score = 2.0

        # 7. Strategy Validation (Max 10 points)
        strategy_score = 10.0 if strategy_confirmed else 2.0
        
        total = round(
            trend_score + tech_score + momentum_score + structure_score + vol_score + rr_score + strategy_score,
            1
        )
        total = min(max(total, 0.0), 100.0)

        return OpportunityScoreBreakdown(
            trend_alignment=round(trend_score, 1),
            technical_confirmation=round(tech_score, 1),
            momentum=round(momentum_score, 1),
            market_structure=round(structure_score, 1),
            volatility=round(vol_score, 1),
            risk_reward=round(rr_score, 1),
            strategy_validation=round(strategy_score, 1),
            total_score=total
        )

