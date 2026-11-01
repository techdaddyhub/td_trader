"""TD TRADER - Core Configuration Management
Production configuration with security defaults, environment overrides, and modular service discovery.
"""

import os
import base64
import hashlib
from typing import List, Optional
from pydantic import BaseModel, Field

class Settings(BaseModel):
    PROJECT_NAME: str = "TD TRADER"
    VERSION: str = "2.0.0"
    TAGLINE: str = "Trade Smarter. Think Faster. Let AI Explain."
    API_PREFIX: str = "/api/v1"
    
    # Security & Encryption
    SECRET_KEY: str = Field(
        default=os.getenv("TD_SECRET_KEY", "td-trader-super-secure-production-secret-key-32-chars-min!"),
        description="Master secret key for JWT session tokens"
    )
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24  # 24 hours
    
    # AES-256 Master Key for Broker Credentials
    # Generated from SECRET_KEY using SHA-256 and Base64 URL-safe encoding
    @property
    def CREDENTIAL_ENCRYPTION_KEY(self) -> bytes:
        raw_key = os.getenv("TD_CRED_ENCRYPT_KEY", self.SECRET_KEY)
        key_hash = hashlib.sha256(raw_key.encode()).digest()
        return base64.urlsafe_b64encode(key_hash)
        
    # Database
    DATABASE_URL: str = os.getenv(
        "DATABASE_URL", 
        "sqlite:///./td_trader_database.sqlite"
    )
    
    # Real-Time Event Broker
    WS_HEARTBEAT_INTERVAL_SEC: int = 15
    MAX_WS_CONNECTIONS_PER_USER: int = 10
    
    # Market Data Providers (Modular: Simulator, RealTick, YahooFinance, MetaTraderBridge)
    MARKET_DATA_PROVIDER: str = os.getenv("MARKET_DATA_PROVIDER", "hybrid_realtime")
    SCANNER_INTERVAL_SECONDS: int = 5
    ENABLE_REAL_TIME_TICK_SIMULATOR: bool = True
    
    # AI Engine Settings
    AI_PROVIDER: str = os.getenv("AI_PROVIDER", "gemini_pro")  # gemini_pro, openai, claude, local_rule_engine
    GEMINI_API_KEY: Optional[str] = os.getenv("GEMINI_API_KEY", "")
    VOICE_DEFAULT_PERSONALITY: str = "Aria_Fintech_Pro"
    VOICE_DEFAULT_SPEED: float = 1.05
    VOICE_DEFAULT_VOLUME: float = 1.0
    
    # Smart Risk Guardian Defaults (Strict Risk-First)
    DEFAULT_MAX_RISK_PER_TRADE_PCT: float = 1.0  # 1% equity max per trade
    DEFAULT_MAX_DAILY_LOSS_PCT: float = 3.0       # 3% daily account loss threshold
    DEFAULT_MAX_DAILY_DRAWDOWN_PCT: float = 4.0   # 4% daily trailing drawdown threshold
    DEFAULT_MAX_ACCOUNT_DRAWDOWN_PCT: float = 8.0 # 8% total account equity drawdown
    DEFAULT_MAX_OPEN_TRADES: int = 5
    DEFAULT_MAX_CORRELATED_EXPOSURE: int = 2      # Max 2 trades on currency/asset cluster
    DEFAULT_CONSECUTIVE_LOSS_LIMIT: int = 3       # Auto-suspend after 3 back-to-back losses
    
    # MetaTrader Bridge Ports
    MT4_BRIDGE_PORT: int = 5555
    MT5_BRIDGE_PORT: int = 5556
    
    # CORS
    ALLOWED_ORIGINS: List[str] = ["*"]

settings = Settings()

