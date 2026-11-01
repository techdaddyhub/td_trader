"""TD TRADER - High-Precision Quantitative Technical Indicators
Mathematical implementations of core indicators, volatility metrics, and oscillators.
"""

from typing import List, Dict, Any, Tuple
import numpy as np
import pandas as pd

class TechnicalIndicators:
    @staticmethod
    def calculate_ema(prices: pd.Series, period: int) -> pd.Series:
        """Exponential Moving Average."""
        return prices.ewm(span=period, adjust=False).mean()

    @staticmethod
    def calculate_sma(prices: pd.Series, period: int) -> pd.Series:
        """Simple Moving Average."""
        return prices.rolling(window=period).mean()

    @staticmethod
    def calculate_rsi(prices: pd.Series, period: int = 14) -> pd.Series:
        """Relative Strength Index (Wilder's RSI)."""
        delta = prices.diff()
        gain = (delta.where(delta > 0, 0)).rolling(window=period).mean()
        loss = (-delta.where(delta < 0, 0)).rolling(window=period).mean()
        
        # Avoid division by zero
        rs = gain / loss.replace(0, np.nan)
        rsi = 100 - (100 / (1 + rs))
        return rsi.fillna(50)

    @staticmethod
    def calculate_macd(
        prices: pd.Series, 
        fast_period: int = 12, 
        slow_period: int = 26, 
        signal_period: int = 9
    ) -> Tuple[pd.Series, pd.Series, pd.Series]:
        """Moving Average Convergence Divergence (MACD Line, Signal Line, Histogram)."""
        fast_ema = TechnicalIndicators.calculate_ema(prices, fast_period)
        slow_ema = TechnicalIndicators.calculate_ema(prices, slow_period)
        macd_line = fast_ema - slow_ema
        signal_line = TechnicalIndicators.calculate_ema(macd_line, signal_period)
        histogram = macd_line - signal_line
        return macd_line, signal_line, histogram

    @staticmethod
    def calculate_bollinger_bands(
        prices: pd.Series, 
        period: int = 20, 
        std_dev: float = 2.0
    ) -> Tuple[pd.Series, pd.Series, pd.Series, pd.Series]:
        """Bollinger Bands (Upper, Middle, Lower, Bandwidth)."""
        middle_band = TechnicalIndicators.calculate_sma(prices, period)
        rolling_std = prices.rolling(window=period).std()
        upper_band = middle_band + (rolling_std * std_dev)
        lower_band = middle_band - (rolling_std * std_dev)
        bandwidth = (upper_band - lower_band) / middle_band.replace(0, np.nan)
        return upper_band, middle_band, lower_band, bandwidth

    @staticmethod
    def calculate_atr(df: pd.DataFrame, period: int = 14) -> pd.Series:
        """Average True Range (ATR) for volatility measurement."""
        high = df['high']
        low = df['low']
        close_prev = df['close'].shift(1)
        
        tr1 = high - low
        tr2 = (high - close_prev).abs()
        tr3 = (low - close_prev).abs()
        
        tr = pd.concat([tr1, tr2, tr3], axis=1).max(axis=1)
        atr = tr.ewm(alpha=1/period, adjust=False).mean()
        return atr

    @staticmethod
    def calculate_supertrend(
        df: pd.DataFrame, 
        period: int = 10, 
        multiplier: float = 3.0
    ) -> Tuple[pd.Series, pd.Series]:
        """Supertrend Trend-Following Indicator (Supertrend Line, Direction: 1 Bull, -1 Bear)."""
        atr = TechnicalIndicators.calculate_atr(df, period)
        hl2 = (df['high'] + df['low']) / 2
        
        upper_band = hl2 + (multiplier * atr)
        lower_band = hl2 - (multiplier * atr)
        
        supertrend = pd.Series(index=df.index, dtype='float64')
        direction = pd.Series(index=df.index, dtype='int64')
        
        direction.iloc[0] = 1
        supertrend.iloc[0] = lower_band.iloc[0]
        
        for i in range(1, len(df)):
            curr_close = df['close'].iloc[i]
            prev_upper = upper_band.iloc[i-1]
            prev_lower = lower_band.iloc[i-1]
            prev_supertrend = supertrend.iloc[i-1]
            prev_direction = direction.iloc[i-1]
            
            curr_upper = upper_band.iloc[i]
            curr_lower = lower_band.iloc[i]
            
            if curr_lower > prev_lower or df['close'].iloc[i-1] < prev_lower:
                lower_band.iloc[i] = curr_lower
            else:
                lower_band.iloc[i] = prev_lower
                
            if curr_upper < prev_upper or df['close'].iloc[i-1] > prev_upper:
                upper_band.iloc[i] = curr_upper
            else:
                upper_band.iloc[i] = prev_upper
                
            if prev_direction == 1:
                if curr_close < lower_band.iloc[i]:
                    direction.iloc[i] = -1
                    supertrend.iloc[i] = upper_band.iloc[i]
                else:
                    direction.iloc[i] = 1
                    supertrend.iloc[i] = lower_band.iloc[i]
            else:
                if curr_close > upper_band.iloc[i]:
                    direction.iloc[i] = 1
                    supertrend.iloc[i] = lower_band.iloc[i]
                else:
                    direction.iloc[i] = -1
                    supertrend.iloc[i] = upper_band.iloc[i]
                    
        return supertrend, direction

