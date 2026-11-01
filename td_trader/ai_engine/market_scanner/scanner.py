"""TD TRADER - MODULE 1: AI Multi-Market Real-Time Scanner Engine
Continuously scans Forex, Crypto, Metals, Indices, and Commodities across multi-timeframes.
Applies technical confluence, market structure analysis, and transparent opportunity ranking.
"""

from typing import List, Dict, Any, Optional
from datetime import datetime, timedelta
import pandas as pd
from td_trader.ai_engine.market_scanner.market_data_feed import market_data_feed, INSTRUMENT_CATALOG
from td_trader.ai_engine.technical_analysis.indicators import TechnicalIndicators
from td_trader.ai_engine.technical_analysis.market_structure import MarketStructureAnalyzer
from td_trader.ai_engine.strategy_engine.strategies import STRATEGY_REGISTRY
from td_trader.ai_engine.opportunity_ranker.ranker import OpportunityRanker
from td_trader.backend.app.schemas.schemas import SignalResponse, OpportunityScoreBreakdown, ScannerFilterParams

class AIMarketScanner:
    """Intelligent real-time multi-market scanner and confluence ranking engine."""
    
    def __init__(self):
        self.monitored_instruments: List[str] = list(INSTRUMENT_CATALOG.keys())
        self.active_timeframes: List[str] = ["M15", "H1", "H4"]
        self.current_opportunities: List[SignalResponse] = []
        self.last_scan_time: Optional[datetime] = None

    def add_monitored_instrument(self, symbol: str):
        if symbol in INSTRUMENT_CATALOG and symbol not in self.monitored_instruments:
            self.monitored_instruments.append(symbol)

    def remove_monitored_instrument(self, symbol: str):
        if symbol in self.monitored_instruments:
            self.monitored_instruments.remove(symbol)

    def scan_all_markets(self) -> List[SignalResponse]:
        """Perform comprehensive scan across all monitored markets and timeframes."""
        discovered_opportunities: List[SignalResponse] = []
        signal_id_counter = 1
        
        for symbol in self.monitored_instruments:
            meta = INSTRUMENT_CATALOG.get(symbol)
            if not meta:
                continue
                
            quote = market_data_feed.get_latest_quote(symbol)
            is_real_time = quote.get("is_real_time", True) if quote else True
            delay_sec = quote.get("data_delay_seconds", 0) if quote else 0
            
            for tf in self.active_timeframes:
                try:
                    df = market_data_feed.get_ohlcv(symbol, tf)
                except Exception:
                    continue
                    
                if len(df) < 50:
                    continue
                    
                # Run Market Structure Analysis
                structure = MarketStructureAnalyzer.detect_market_structure(df)
                sweeps = MarketStructureAnalyzer.detect_liquidity_sweeps(df)
                zones = MarketStructureAnalyzer.identify_supply_demand_zones(df)
                breakouts = MarketStructureAnalyzer.detect_breakouts(df)
                
                # Run Quantitative Indicators
                rsi = TechnicalIndicators.calculate_rsi(df['close'], 14)
                macd_line, sig_line, hist = TechnicalIndicators.calculate_macd(df['close'])
                supertrend, direction = TechnicalIndicators.calculate_supertrend(df)
                atr = TechnicalIndicators.calculate_atr(df, 14)
                
                curr_rsi = float(rsi.iloc[-1])
                curr_hist = float(hist.iloc[-1])
                curr_supertrend_dir = int(direction.iloc[-1])
                curr_atr = float(atr.iloc[-1])
                avg_atr = float(atr.iloc[-20:].mean()) if len(atr) >= 20 else curr_atr
                atr_ratio = curr_atr / max(avg_atr, 0.00001)
                
                # Check all registered strategies
                for strat_name, strat_cls in STRATEGY_REGISTRY.items():
                    strat = strat_cls()
                    eval_result = strat.evaluate(df)
                    
                    if eval_result.get("triggered", False):
                        trade_dir = eval_result["direction"]
                        entry_p = eval_result["entry_price"]
                        sl_p = eval_result["stop_loss"]
                        tp1_p = eval_result["take_profit_1"]
                        tp2_p = eval_result.get("take_profit_2")
                        rr = eval_result.get("risk_reward", 2.0)
                        
                        # Trend alignment check
                        trend_aligned = (trade_dir == "BUY" and structure["trend"] == "BULLISH") or \
                                        (trade_dir == "SELL" and structure["trend"] == "BEARISH")
                        trend_strength = 0.85 if trend_aligned else 0.35
                        
                        # Supply / Demand confluence
                        sd_confluence = False
                        if trade_dir == "BUY" and zones["demand_zones"]:
                            last_dz = zones["demand_zones"][-1]
                            if abs(entry_p - last_dz["high"]) < (2 * curr_atr):
                                sd_confluence = True
                        elif trade_dir == "SELL" and zones["supply_zones"]:
                            last_sz = zones["supply_zones"][-1]
                            if abs(entry_p - last_sz["low"]) < (2 * curr_atr):
                                sd_confluence = True
                                
                        sweep_present = len(sweeps) > 0 and sweeps[-1]["direction_bias"].startswith(trade_dir)
                        
                        # Calculate transparent score
                        breakdown = OpportunityRanker.calculate_score(
                            trend_aligned=trend_aligned,
                            trend_strength=trend_strength,
                            rsi_value=curr_rsi,
                            macd_histogram=curr_hist,
                            supertrend_direction=curr_supertrend_dir,
                            market_structure=structure.get("last_bos") or structure.get("last_choch") or structure["trend"],
                            liquidity_sweep_present=sweep_present,
                            supply_demand_confluence=sd_confluence,
                            atr_ratio=atr_ratio,
                            risk_reward_ratio=rr,
                            strategy_confirmed=True,
                            direction=trade_dir
                        )
                        
                        # Construct institutional AI rationale
                        ai_rationale = (
                            f"Identified {trade_dir} confluence on {symbol} ({tf}) using {strat_name}. "
                            f"Market structure is {structure['trend']} with {structure.get('last_bos') or 'consistent swing continuity'}. "
                            f"RSI is at {curr_rsi:.1f}, MACD momentum is {'positive' if curr_hist > 0 else 'negative'}, "
                            f"and volatility expansion ratio is {atr_ratio:.2f}. "
                            f"{eval_result.get('rationale', '')}"
                        )
                        
                        sig = SignalResponse(
                            id=signal_id_counter,
                            instrument=symbol,
                            market_category=meta["category"],
                            direction=trade_dir,
                            timeframe=tf,
                            entry_price=round(entry_p, meta["digits"]),
                            stop_loss=round(sl_p, meta["digits"]),
                            take_profit_1=round(tp1_p, meta["digits"]),
                            take_profit_2=round(tp2_p, meta["digits"]) if tp2_p else None,
                            take_profit_3=None,
                            risk_reward_ratio=rr,
                            score=breakdown.total_score,
                            score_breakdown=breakdown,
                            strategy_name=strat_name,
                            market_structure=structure.get("last_bos") or structure.get("last_choch") or structure["trend"],
                            status="ACTIVE",
                            ai_rationale=ai_rationale,
                            created_at=datetime.utcnow(),
                            is_real_time=is_real_time,
                            data_delay_seconds=delay_sec
                        )
                        
                        discovered_opportunities.append(sig)
                        signal_id_counter += 1
                        
        # Sort opportunities descending by score (highest confluence first)
        discovered_opportunities.sort(key=lambda s: s.score, reverse=True)
        self.current_opportunities = discovered_opportunities
        self.last_scan_time = datetime.utcnow()
        return self.current_opportunities

    def get_filtered_opportunities(self, params: ScannerFilterParams) -> List[SignalResponse]:
        """Filter opportunities according to user dashboard selection."""
        results = self.current_opportunities if self.current_opportunities else self.scan_all_markets()
        
        filtered = []
        for opp in results:
            if params.market_category and opp.market_category.upper() != params.market_category.upper():
                continue
            if params.instrument and opp.instrument.upper() != params.instrument.upper():
                continue
            if params.timeframe and opp.timeframe.upper() != params.timeframe.upper():
                continue
            if params.direction and opp.direction.upper() != params.direction.upper():
                continue
            if params.strategy and opp.strategy_name.upper() != params.strategy.upper():
                continue
            if opp.score < params.min_score:
                continue
            filtered.append(opp)
            
        return filtered

ai_market_scanner = AIMarketScanner()

