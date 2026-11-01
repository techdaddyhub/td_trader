"""TD TRADER - Market Structure & Institutional Smart Money Analysis
Detects BOS, CHoCH, Liquidity Sweeps, Supply/Demand Zones, Support/Resistance,
Fair Value Gaps, and Breakout Validity.
"""

from typing import List, Dict, Any, Optional, Tuple
import numpy as np
import pandas as pd

class MarketStructureAnalyzer:
    @staticmethod
    def identify_swing_points(df: pd.DataFrame, left_bars: int = 3, right_bars: int = 3) -> pd.DataFrame:
        """Identify swing highs and swing lows across the time series."""
        df = df.copy()
        df['is_swing_high'] = False
        df['is_swing_low'] = False
        
        highs = df['high'].values
        lows = df['low'].values
        n = len(df)
        
        for i in range(left_bars, n - right_bars):
            curr_h = highs[i]
            curr_l = lows[i]
            
            # Check swing high
            if all(curr_h > highs[i - k] for k in range(1, left_bars + 1)) and \
               all(curr_h >= highs[i + k] for k in range(1, right_bars + 1)):
                df.iloc[i, df.columns.get_loc('is_swing_high')] = True
                
            # Check swing low
            if all(curr_l < lows[i - k] for k in range(1, left_bars + 1)) and \
               all(curr_l <= lows[i + k] for k in range(1, right_bars + 1)):
                df.iloc[i, df.columns.get_loc('is_swing_low')] = True
                
        return df

    @staticmethod
    def detect_market_structure(df: pd.DataFrame) -> Dict[str, Any]:
        """Detect current trend, BOS (Break of Structure), and CHoCH (Change of Character)."""
        swings_df = MarketStructureAnalyzer.identify_swing_points(df)
        swing_highs = swings_df[swings_df['is_swing_high']][['high']].reset_index()
        swing_lows = swings_df[swings_df['is_swing_low']][['low']].reset_index()
        
        current_close = df['close'].iloc[-1]
        structure = {
            "trend": "SIDEWAYS",
            "last_bos": None,
            "last_choch": None,
            "higher_highs": False,
            "lower_lows": False,
            "key_swing_high": float(df['high'].max()),
            "key_swing_low": float(df['low'].min())
        }
        
        if len(swing_highs) >= 2 and len(swing_lows) >= 2:
            h1 = swing_highs['high'].iloc[-2]
            h2 = swing_highs['high'].iloc[-1]
            l1 = swing_lows['low'].iloc[-2]
            l2 = swing_lows['low'].iloc[-1]
            
            structure["key_swing_high"] = float(h2)
            structure["key_swing_low"] = float(l2)
            
            # Bullish Market Structure: HH and HL
            if h2 > h1 and l2 > l1:
                structure["trend"] = "BULLISH"
                structure["higher_highs"] = True
                if current_close > h2:
                    structure["last_bos"] = "BOS_BULLISH_CONTINUATION"
                elif current_close < l2:
                    structure["last_choch"] = "CHOCH_BEARISH_REVERSAL"
                    
            # Bearish Market Structure: LH and LL
            elif h2 < h1 and l2 < l1:
                structure["trend"] = "BEARISH"
                structure["lower_lows"] = True
                if current_close < l2:
                    structure["last_bos"] = "BOS_BEARISH_CONTINUATION"
                elif current_close > h2:
                    structure["last_choch"] = "CHOCH_BULLISH_REVERSAL"
                    
        return structure

    @staticmethod
    def detect_liquidity_sweeps(df: pd.DataFrame, lookback: int = 30) -> List[Dict[str, Any]]:
        """Detect buy-side or sell-side liquidity sweeps (fake breakouts with immediate wick rejections)."""
        sweeps = []
        if len(df) < lookback + 5:
            return sweeps
            
        recent = df.iloc[-lookback:].copy()
        swing_high = recent['high'].iloc[:-3].max()
        swing_low = recent['low'].iloc[:-3].min()
        
        # Examine last 3 bars for liquidity grabs
        for idx in range(len(df) - 3, len(df)):
            bar = df.iloc[idx]
            
            # Buy-Side Liquidity (BSL) Sweep: Pierced above resistance high, closed back inside
            if bar['high'] > swing_high and bar['close'] < swing_high:
                upper_wick = bar['high'] - max(bar['open'], bar['close'])
                body = abs(bar['close'] - bar['open'])
                if upper_wick > body: # Significant wick rejection
                    sweeps.append({
                        "type": "BUY_SIDE_LIQUIDITY_SWEEP",
                        "direction_bias": "BEARISH_REVERSAL",
                        "price_level": float(swing_high),
                        "sweep_high": float(bar['high']),
                        "bar_index": int(idx),
                        "description": f"Price swept liquidity above {swing_high:.5f} with sharp wick rejection."
                    })
                    
            # Sell-Side Liquidity (SSL) Sweep: Pierced below support low, closed back inside
            if bar['low'] < swing_low and bar['close'] > swing_low:
                lower_wick = min(bar['open'], bar['close']) - bar['low']
                body = abs(bar['close'] - bar['open'])
                if lower_wick > body:
                    sweeps.append({
                        "type": "SELL_SIDE_LIQUIDITY_SWEEP",
                        "direction_bias": "BULLISH_REVERSAL",
                        "price_level": float(swing_low),
                        "sweep_low": float(bar['low']),
                        "bar_index": int(idx),
                        "description": f"Price swept liquidity below {swing_low:.5f} with sharp wick rejection."
                    })
                    
        return sweeps

    @staticmethod
    def identify_supply_demand_zones(df: pd.DataFrame, threshold_atr_mult: float = 1.8) -> Dict[str, List[Dict[str, Any]]]:
        """Identify institutional supply & demand order blocks formed by strong momentum displacement."""
        high = df['high']
        low = df['low']
        close_prev = df['close'].shift(1)
        tr = pd.concat([high - low, (high - close_prev).abs(), (low - close_prev).abs()], axis=1).max(axis=1)
        atr = tr.rolling(14).mean().bfill()
        
        demand_zones = []
        supply_zones = []
        
        # Look for displacement candles (body > threshold * ATR)
        for i in range(2, len(df) - 1):
            body = abs(df['close'].iloc[i] - df['open'].iloc[i])
            curr_atr = atr.iloc[i]
            
            # Bullish displacement candle -> Base candle is Demand Zone
            if df['close'].iloc[i] > df['open'].iloc[i] and body > (threshold_atr_mult * curr_atr):
                base_candle = df.iloc[i - 1]
                zone_low = base_candle['low']
                zone_high = max(base_candle['open'], base_candle['close'])
                demand_zones.append({
                    "zone_type": "DEMAND_ZONE",
                    "low": float(zone_low),
                    "high": float(zone_high),
                    "strength": round(float(body / curr_atr), 2),
                    "bar_index": int(i - 1)
                })
                
            # Bearish displacement candle -> Base candle is Supply Zone
            elif df['close'].iloc[i] < df['open'].iloc[i] and body > (threshold_atr_mult * curr_atr):
                base_candle = df.iloc[i - 1]
                zone_high = base_candle['high']
                zone_low = min(base_candle['open'], base_candle['close'])
                supply_zones.append({
                    "zone_type": "SUPPLY_ZONE",
                    "low": float(zone_low),
                    "high": float(zone_high),
                    "strength": round(float(body / curr_atr), 2),
                    "bar_index": int(i - 1)
                })
                
        # Return most recent 3 active zones of each
        return {
            "demand_zones": demand_zones[-3:],
            "supply_zones": supply_zones[-3:]
        }

    @staticmethod
    def identify_support_resistance(df: pd.DataFrame, num_clusters: int = 5) -> Dict[str, List[float]]:
        """Cluster swing points into key support and resistance horizontal price levels."""
        swings = MarketStructureAnalyzer.identify_swing_points(df, 3, 3)
        sh_prices = swings[swings['is_swing_high']]['high'].tolist()
        sl_prices = swings[swings['is_swing_low']]['low'].tolist()
        
        curr_price = df['close'].iloc[-1]
        
        resistances = sorted([p for p in sh_prices if p > curr_price])
        supports = sorted([p for p in sl_prices if p < curr_price], reverse=True)
        
        return {
            "immediate_resistances": [round(float(p), 5) for p in resistances[:num_clusters]],
            "immediate_supports": [round(float(p), 5) for p in supports[:num_clusters]]
        }

    @staticmethod
    def detect_breakouts(df: pd.DataFrame) -> Dict[str, Any]:
        """Detect true breakouts vs false breakouts (bull/bear traps) using volume and candle closing."""
        curr = df.iloc[-1]
        prev = df.iloc[-2]
        
        lookback = df.iloc[-25:-1]
        range_high = lookback['high'].max()
        range_low = lookback['low'].min()
        avg_vol = lookback['volume'].mean() if 'volume' in lookback else 1000
        curr_vol = curr['volume'] if 'volume' in curr else avg_vol
        
        result = {"is_breakout": False, "type": "NONE", "validity": "UNCONFIRMED"}
        
        # Bullish Breakout
        if curr['close'] > range_high:
            is_high_volume = curr_vol >= (avg_vol * 1.3)
            result = {
                "is_breakout": True,
                "type": "BULLISH_BREAKOUT",
                "validity": "CONFIRMED" if is_high_volume else "SUSPICIOUS_LOW_VOLUME",
                "breakout_level": float(range_high),
                "volume_ratio": round(float(curr_vol / avg_vol), 2)
            }
        # Bearish Breakout
        elif curr['close'] < range_low:
            is_high_volume = curr_vol >= (avg_vol * 1.3)
            result = {
                "is_breakout": True,
                "type": "BEARISH_BREAKOUT",
                "validity": "CONFIRMED" if is_high_volume else "SUSPICIOUS_LOW_VOLUME",
                "breakout_level": float(range_low),
                "volume_ratio": round(float(curr_vol / avg_vol), 2)
            }
        # False breakout / Bull Trap check
        elif prev['high'] > range_high and curr['close'] < range_high:
            result = {
                "is_breakout": True,
                "type": "BULL_TRAP_FALSE_BREAKOUT",
                "validity": "REVERSAL_CONFIRMED",
                "breakout_level": float(range_high)
            }
        # False breakout / Bear Trap check
        elif prev['low'] < range_low and curr['close'] > range_low:
            result = {
                "is_breakout": True,
                "type": "BEAR_TRAP_FALSE_BREAKOUT",
                "validity": "REVERSAL_CONFIRMED",
                "breakout_level": float(range_low)
            }
            
        return result
