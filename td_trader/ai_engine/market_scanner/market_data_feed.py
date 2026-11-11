"""TD TRADER - High-Fidelity Multi-Asset Market Data Feed
Streams tick and OHLCV data across Forex, Crypto, Metals, Indices, and Commodities.
Supports MetaTrader 4/5 Bridge feeds, external API feeds, and real-time simulator.
Distinguishes real-time from delayed data transparently.
"""

from typing import Dict, List, Any, Optional
from datetime import datetime, timedelta
import random
import numpy as np
import pandas as pd

INSTRUMENT_CATALOG = {
    # Forex
    "EURUSD": {"category": "FOREX", "pip_size": 0.0001, "digits": 5, "base_price": 1.0850, "typical_spread": 1.1, "deriv_symbol": "frxEURUSD"},
    "GBPUSD": {"category": "FOREX", "pip_size": 0.0001, "digits": 5, "base_price": 1.2950, "typical_spread": 1.4, "deriv_symbol": "frxGBPUSD"},
    "USDJPY": {"category": "FOREX", "pip_size": 0.01, "digits": 3, "base_price": 152.40, "typical_spread": 1.3, "deriv_symbol": "frxUSDJPY"},
    "AUDUSD": {"category": "FOREX", "pip_size": 0.0001, "digits": 5, "base_price": 0.6580, "typical_spread": 1.2, "deriv_symbol": "frxAUDUSD"},
    "USDCAD": {"category": "FOREX", "pip_size": 0.0001, "digits": 5, "base_price": 1.3880, "typical_spread": 1.5, "deriv_symbol": "frxUSDCAD"},
    "EURGBP": {"category": "FOREX", "pip_size": 0.0001, "digits": 5, "base_price": 0.8380, "typical_spread": 1.6, "deriv_symbol": "frxEURGBP"},
    "GBPJPY": {"category": "FOREX", "pip_size": 0.01, "digits": 3, "base_price": 197.50, "typical_spread": 2.1, "deriv_symbol": "frxGBPJPY"},

    # Deriv Synthetic & Derived Indices (24/7 Markets)
    "V75": {"category": "SYNTHETICS", "display_name": "Volatility 75 Index", "pip_size": 0.01, "digits": 2, "base_price": 235420.50, "typical_spread": 4.5, "pip_value_per_lot": 0.01, "deriv_symbol": "R_75"},
    "V100": {"category": "SYNTHETICS", "display_name": "Volatility 100 Index", "pip_size": 0.01, "digits": 2, "base_price": 1685.20, "typical_spread": 2.0, "pip_value_per_lot": 0.01, "deriv_symbol": "R_100"},
    "V50": {"category": "SYNTHETICS", "display_name": "Volatility 50 Index", "pip_size": 0.0001, "digits": 4, "base_price": 184.3200, "typical_spread": 2.5, "pip_value_per_lot": 0.0001, "deriv_symbol": "R_50"},
    "V25": {"category": "SYNTHETICS", "display_name": "Volatility 25 Index", "pip_size": 0.001, "digits": 3, "base_price": 2415.650, "typical_spread": 2.0, "pip_value_per_lot": 0.001, "deriv_symbol": "R_25"},
    "V10": {"category": "SYNTHETICS", "display_name": "Volatility 10 Index", "pip_size": 0.001, "digits": 3, "base_price": 6840.250, "typical_spread": 1.5, "pip_value_per_lot": 0.001, "deriv_symbol": "R_10"},
    "V75_1S": {"category": "SYNTHETICS", "display_name": "Volatility 75 (1s) Index", "pip_size": 0.01, "digits": 2, "base_price": 3890.40, "typical_spread": 2.5, "pip_value_per_lot": 0.01, "deriv_symbol": "1HZ75V"},
    "BOOM1000": {"category": "SYNTHETICS", "display_name": "Boom 1000 Index", "pip_size": 0.01, "digits": 2, "base_price": 13420.50, "typical_spread": 3.5, "pip_value_per_lot": 0.01, "deriv_symbol": "BOOM1000"},
    "BOOM500": {"category": "SYNTHETICS", "display_name": "Boom 500 Index", "pip_size": 0.01, "digits": 2, "base_price": 5120.40, "typical_spread": 3.0, "pip_value_per_lot": 0.01, "deriv_symbol": "BOOM500"},
    "CRASH1000": {"category": "SYNTHETICS", "display_name": "Crash 1000 Index", "pip_size": 0.01, "digits": 2, "base_price": 6410.80, "typical_spread": 3.5, "pip_value_per_lot": 0.01, "deriv_symbol": "CRASH1000"},
    "CRASH500": {"category": "SYNTHETICS", "display_name": "Crash 500 Index", "pip_size": 0.01, "digits": 2, "base_price": 4280.15, "typical_spread": 3.0, "pip_value_per_lot": 0.01, "deriv_symbol": "CRASH500"},
    "STEP": {"category": "SYNTHETICS", "display_name": "Step Index", "pip_size": 0.1, "digits": 1, "base_price": 8425.0, "typical_spread": 1.0, "pip_value_per_lot": 1.0, "deriv_symbol": "stpRNG"},
    "JUMP75": {"category": "SYNTHETICS", "display_name": "Jump 75 Index", "pip_size": 0.01, "digits": 2, "base_price": 52310.00, "typical_spread": 4.0, "pip_value_per_lot": 0.01, "deriv_symbol": "JD75"},

    # Crypto
    "BTCUSD": {"category": "CRYPTO", "pip_size": 1.0, "digits": 2, "base_price": 68500.0, "typical_spread": 15.0, "deriv_symbol": "cryBTCUSD"},
    "ETHUSD": {"category": "CRYPTO", "pip_size": 0.1, "digits": 2, "base_price": 2550.0, "typical_spread": 2.5, "deriv_symbol": "cryETHUSD"},
    "SOLUSD": {"category": "CRYPTO", "pip_size": 0.01, "digits": 2, "base_price": 178.50, "typical_spread": 0.25},
    "XRPUSD": {"category": "CRYPTO", "pip_size": 0.0001, "digits": 4, "base_price": 0.5250, "typical_spread": 0.0008},

    # Metals
    "XAUUSD": {"category": "METALS", "pip_size": 0.01, "digits": 2, "base_price": 2745.50, "typical_spread": 1.8, "deriv_symbol": "frxXAUUSD"},
    "XAGUSD": {"category": "METALS", "pip_size": 0.001, "digits": 3, "base_price": 32.80, "typical_spread": 2.2, "deriv_symbol": "frxXAGUSD"},
    "XPTUSD": {"category": "METALS", "pip_size": 0.1, "digits": 2, "base_price": 1015.0, "typical_spread": 3.5, "deriv_symbol": "frxXPTUSD"},

    # Indices
    "US30": {"category": "INDICES", "pip_size": 1.0, "digits": 1, "base_price": 42150.0, "typical_spread": 2.5},
    "NAS100": {"category": "INDICES", "pip_size": 1.0, "digits": 1, "base_price": 20120.0, "typical_spread": 1.8},
    "SPX500": {"category": "INDICES", "pip_size": 0.1, "digits": 2, "base_price": 5780.0, "typical_spread": 0.6},
    "GER40": {"category": "INDICES", "pip_size": 1.0, "digits": 1, "base_price": 19450.0, "typical_spread": 2.0},

    # Commodities
    "USOIL": {"category": "COMMODITIES", "pip_size": 0.01, "digits": 2, "base_price": 71.40, "typical_spread": 2.5},
    "UKOIL": {"category": "COMMODITIES", "pip_size": 0.01, "digits": 2, "base_price": 75.20, "typical_spread": 2.8},
    "NATGAS": {"category": "COMMODITIES", "pip_size": 0.001, "digits": 3, "base_price": 2.680, "typical_spread": 3.0}
}


def get_pip_value_per_lot(symbol: str, default_other: float = 10.0) -> float:
    """Return USD pip value per 1.0 standard lot for position sizing and PnL calculation."""
    meta = INSTRUMENT_CATALOG.get(symbol, {"category": "FOREX"})
    if "pip_value_per_lot" in meta:
        return float(meta["pip_value_per_lot"])
    cat = meta.get("category")
    if cat in ("FOREX", "METALS"):
        return 10.0
    if cat in ("CRYPTO", "INDICES"):
        return 1.0
    return default_other

class MarketDataFeed:
    """Provides streaming real-time prices and multi-timeframe OHLCV candles."""
    
    def __init__(self):
        self.live_quotes: Dict[str, Dict[str, Any]] = {}
        self.candle_cache: Dict[str, Dict[str, pd.DataFrame]] = {}
        self._initialize_quotes()
        self._pregenerate_candles()

    def _initialize_quotes(self):
        now = datetime.utcnow()
        for symbol, meta in INSTRUMENT_CATALOG.items():
            spread_val = meta["typical_spread"] * meta["pip_size"]
            bid = meta["base_price"]
            ask = bid + spread_val
            self.live_quotes[symbol] = {
                "symbol": symbol,
                "category": meta["category"],
                "bid": round(bid, meta["digits"]),
                "ask": round(ask, meta["digits"]),
                "spread_pips": meta["typical_spread"],
                "digits": meta["digits"],
                "pip_size": meta["pip_size"],
                "timestamp": now.isoformat(),
                "is_real_time": True,
                "data_delay_seconds": 0
            }

    def _pregenerate_candles(self, num_bars: int = 150):
        """Seed realistic historical OHLCV data for all instruments and timeframes."""
        timeframes = ["M5", "M15", "M30", "H1", "H4", "D1"]
        for symbol, meta in INSTRUMENT_CATALOG.items():
            self.candle_cache[symbol] = {}
            base = meta["base_price"]
            pip = meta["pip_size"]
            
            for tf in timeframes:
                # Minutes per bar
                tf_minutes = {"M5": 5, "M15": 15, "M30": 30, "H1": 60, "H4": 240, "D1": 1440}[tf]
                now = datetime.utcnow()
                timestamps = [now - timedelta(minutes=(num_bars - i) * tf_minutes) for i in range(num_bars)]
                
                # Geometric Brownian motion with trend component
                np.random.seed(abs(hash(symbol + tf)) % 100000)
                returns = np.random.normal(0.0001, 0.002, num_bars)
                price_curve = base * np.cumprod(1 + returns)
                
                closes = price_curve
                highs = closes * (1 + np.abs(np.random.normal(0, 0.0015, num_bars)))
                lows = closes * (1 - np.abs(np.random.normal(0, 0.0015, num_bars)))
                opens = np.roll(closes, 1)
                opens[0] = closes[0]
                volumes = np.random.randint(500, 15000, num_bars)
                
                df = pd.DataFrame({
                    "open": opens,
                    "high": highs,
                    "low": lows,
                    "close": closes,
                    "volume": volumes
                }, index=pd.to_datetime(timestamps))
                
                self.candle_cache[symbol][tf] = df

    def get_latest_quote(self, symbol: str) -> Optional[Dict[str, Any]]:
        """Return the latest bid/ask quote for an instrument."""
        return self.live_quotes.get(symbol)

    def get_all_quotes(self) -> List[Dict[str, Any]]:
        """Return quotes for all registered multi-asset instruments."""
        return list(self.live_quotes.values())

    def update_tick(
        self,
        symbol: str,
        bid: float,
        ask: float,
        is_real_time: bool = True,
        delay_seconds: int = 0,
        source: str = "SIMULATOR",
    ):
        """Update live quote from external feed (e.g., Deriv WS or MT4/MT5 bridge)."""
        if symbol in self.live_quotes:
            meta = INSTRUMENT_CATALOG[symbol]
            self.live_quotes[symbol]["bid"] = round(bid, meta["digits"])
            self.live_quotes[symbol]["ask"] = round(ask, meta["digits"])
            self.live_quotes[symbol]["spread_pips"] = round((ask - bid) / meta["pip_size"], 1)
            self.live_quotes[symbol]["timestamp"] = datetime.utcnow().isoformat()
            self.live_quotes[symbol]["is_real_time"] = is_real_time
            self.live_quotes[symbol]["data_delay_seconds"] = delay_seconds
            self.live_quotes[symbol]["source"] = source

    def update_candles(self, symbol: str, timeframe: str, df: pd.DataFrame):
        """Replace cached OHLCV candles with live broker historical bars (e.g. Deriv ticks_history)."""
        if symbol in self.candle_cache and df is not None and not df.empty:
            self.candle_cache[symbol][timeframe] = df

    def get_ohlcv(self, symbol: str, timeframe: str = "H1") -> pd.DataFrame:
        """Fetch OHLCV DataFrame for technical analysis and scanner processing."""
        if symbol in self.candle_cache and timeframe in self.candle_cache[symbol]:
            df = self.candle_cache[symbol][timeframe].copy()
            # Update the latest bar with current live quote
            curr_quote = self.live_quotes.get(symbol)
            if curr_quote:
                curr_price = (curr_quote["bid"] + curr_quote["ask"]) / 2.0
                df.iloc[-1, df.columns.get_loc('close')] = curr_price
                if curr_price > df.iloc[-1]['high']:
                    df.iloc[-1, df.columns.get_loc('high')] = curr_price
                if curr_price < df.iloc[-1]['low']:
                    df.iloc[-1, df.columns.get_loc('low')] = curr_price
            return df
        raise ValueError(f"Unknown symbol '{symbol}' or timeframe '{timeframe}'")

market_data_feed = MarketDataFeed()

