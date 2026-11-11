"""TD TRADER - Database Architecture & SQLAlchemy Models
Enterprise schema supporting multi-account isolation, Smart Risk Guardian states,
audit logs, trading journals, signals, orders, and backtest results.
"""

from datetime import datetime
import json
from typing import Optional, Dict, Any
from sqlalchemy import (
    create_engine, Column, Integer, String, Float, Boolean, DateTime, Text, ForeignKey
)
from sqlalchemy.orm import declarative_base, relationship, sessionmaker, scoped_session
from td_trader.backend.app.core.config import settings

Base = declarative_base()

class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, index=True, nullable=False)
    full_name = Column(String(255), nullable=False)
    hashed_password = Column(String(255), nullable=False)
    is_active = Column(Boolean, default=True)
    is_superuser = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    accounts = relationship("TradingAccount", back_populates="user", cascade="all, delete-orphan")
    strategies = relationship("Strategy", back_populates="user", cascade="all, delete-orphan")
    journal_entries = relationship("TradingJournalEntry", back_populates="user", cascade="all, delete-orphan")

class TradingAccount(Base):
    """Trading Account with strict account isolation and encrypted credentials."""
    __tablename__ = "trading_accounts"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    account_number = Column(String(100), nullable=False)
    broker_name = Column(String(100), nullable=False)
    server = Column(String(150), nullable=False)
    platform = Column(String(50), nullable=False)  # MT4_DEMO, MT4_LIVE, MT5_DEMO, MT5_LIVE, DERIV_API_DEMO, DERIV_API_LIVE, PAPER_TRADING
    currency = Column(String(10), default="USD")
    
    # Encrypted password (AES-256) - never store plaintext
    encrypted_credentials = Column(Text, nullable=True)
    
    # Account Balance & Equity Metrics
    balance = Column(Float, default=10000.0)
    equity = Column(Float, default=10000.0)
    free_margin = Column(Float, default=10000.0)
    used_margin = Column(Float, default=0.0)
    floating_pnl = Column(Float, default=0.0)
    
    # Status & Authorization
    connection_status = Column(String(50), default="CONNECTED")  # CONNECTED, DISCONNECTED, ERROR
    is_auto_trading_enabled = Column(Boolean, default=False)     # Requires explicit authorization
    is_authorized_live = Column(Boolean, default=False)          # Explicit authorization flag for live capital
    
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    user = relationship("User", back_populates="accounts")
    risk_config = relationship("RiskConfiguration", back_populates="account", uselist=False, cascade="all, delete-orphan")
    orders = relationship("Order", back_populates="account", cascade="all, delete-orphan")
    positions = relationship("Position", back_populates="account", cascade="all, delete-orphan")

class RiskConfiguration(Base):
    """Smart Risk Guardian configuration per account."""
    __tablename__ = "risk_configurations"
    
    id = Column(Integer, primary_key=True, index=True)
    account_id = Column(Integer, ForeignKey("trading_accounts.id"), nullable=False, unique=True)
    
    # Risk Thresholds
    risk_per_trade_pct = Column(Float, default=1.0)
    max_daily_loss_pct = Column(Float, default=3.0)
    max_daily_loss_amount = Column(Float, default=300.0)
    max_daily_drawdown_pct = Column(Float, default=4.0)
    max_account_drawdown_pct = Column(Float, default=8.0)
    max_open_trades = Column(Integer, default=5)
    max_correlated_exposure = Column(Integer, default=2)
    max_lot_size = Column(Float, default=5.0)
    consecutive_loss_limit = Column(Integer, default=3)
    
    # Runtime Tracking State
    current_consecutive_losses = Column(Integer, default=0)
    daily_starting_equity = Column(Float, default=10000.0)
    current_daily_loss = Column(Float, default=0.0)
    is_risk_guardian_tripped = Column(Boolean, default=False)
    trip_reason = Column(String(255), nullable=True)
    
    # Guard Rails
    auto_liquidate_on_breach = Column(Boolean, default=False) # False by default: DO NOT auto-liquidate unless user opts-in
    restrict_on_high_impact_news = Column(Boolean, default=True)
    allowed_sessions = Column(String(255), default="LONDON,NEW_YORK,TOKYO")
    emergency_paused = Column(Boolean, default=False)
    
    account = relationship("TradingAccount", back_populates="risk_config")

class Signal(Base):
    """AI Generated Multi-Market Opportunity Signal."""
    __tablename__ = "signals"
    
    id = Column(Integer, primary_key=True, index=True)
    instrument = Column(String(50), nullable=False, index=True) # e.g. XAUUSD, EURUSD, BTCUSD
    market_category = Column(String(50), nullable=False)        # FOREX, CRYPTO, METALS, INDICES, COMMODITIES
    direction = Column(String(10), nullable=False)              # BUY, SELL
    timeframe = Column(String(10), nullable=False)              # M5, M15, M30, H1, H4, D1
    
    # Price Targets
    entry_price = Column(Float, nullable=False)
    stop_loss = Column(Float, nullable=False)
    take_profit_1 = Column(Float, nullable=False)
    take_profit_2 = Column(Float, nullable=True)
    take_profit_3 = Column(Float, nullable=True)
    risk_reward_ratio = Column(Float, nullable=False)
    
    # Scoring & Confluence
    score = Column(Float, nullable=False)  # 0 to 100
    score_breakdown_json = Column(Text, nullable=False)  # JSON breakdown
    strategy_name = Column(String(100), nullable=False)
    market_structure = Column(String(100), nullable=False) # e.g. "BULLISH_BOS", "BEARISH_CHOCH"
    
    # Status
    status = Column(String(50), default="ACTIVE") # ACTIVE, EXECUTED, CANCELLED, INVALIDATED, HIT_TP, HIT_SL
    ai_rationale = Column(Text, nullable=False)
    
    created_at = Column(DateTime, default=datetime.utcnow, index=True)
    expires_at = Column(DateTime, nullable=True)

class Order(Base):
    """Broker and Paper Trading Order records."""
    __tablename__ = "orders"
    
    id = Column(Integer, primary_key=True, index=True)
    client_order_id = Column(String(100), unique=True, index=True, nullable=False)
    broker_ticket = Column(String(100), nullable=True, index=True)
    account_id = Column(Integer, ForeignKey("trading_accounts.id"), nullable=False)
    signal_id = Column(Integer, ForeignKey("signals.id"), nullable=True)
    
    instrument = Column(String(50), nullable=False)
    order_type = Column(String(20), nullable=False) # BUY, SELL, BUY_LIMIT, SELL_LIMIT, BUY_STOP, SELL_STOP
    requested_lots = Column(Float, nullable=False)
    filled_lots = Column(Float, default=0.0)
    requested_price = Column(Float, nullable=False)
    fill_price = Column(Float, nullable=True)
    slippage_pips = Column(Float, default=0.0)
    
    stop_loss = Column(Float, nullable=True)
    take_profit = Column(Float, nullable=True)
    commission = Column(Float, default=0.0)
    swap = Column(Float, default=0.0)
    
    status = Column(String(50), default="SUBMITTED") # SUBMITTED, CONFIRMED, REJECTED, FILLED, CANCELLED
    error_message = Column(Text, nullable=True)
    broker_confirmation_timestamp = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    account = relationship("TradingAccount", back_populates="orders")

class Position(Base):
    """Open or Closed Market Position."""
    __tablename__ = "positions"
    
    id = Column(Integer, primary_key=True, index=True)
    position_ticket = Column(String(100), unique=True, index=True, nullable=False)
    account_id = Column(Integer, ForeignKey("trading_accounts.id"), nullable=False)
    signal_id = Column(Integer, ForeignKey("signals.id"), nullable=True)
    
    instrument = Column(String(50), nullable=False)
    direction = Column(String(10), nullable=False) # BUY, SELL
    lots = Column(Float, nullable=False)
    open_price = Column(Float, nullable=False)
    current_price = Column(Float, nullable=False)
    close_price = Column(Float, nullable=True)
    
    stop_loss = Column(Float, nullable=True)
    take_profit = Column(Float, nullable=True)
    floating_pnl = Column(Float, default=0.0)
    realized_pnl = Column(Float, default=0.0)
    commission = Column(Float, default=0.0)
    swap = Column(Float, default=0.0)
    
    status = Column(String(20), default="OPEN") # OPEN, CLOSED
    close_reason = Column(String(100), nullable=True) # TP, SL, MANUAL, RISK_GUARDIAN_EMERGENCY
    open_time = Column(DateTime, default=datetime.utcnow)
    close_time = Column(DateTime, nullable=True)
    
    account = relationship("TradingAccount", back_populates="positions")

class TradingJournalEntry(Base):
    """Comprehensive Trading Journal with AI Explanations."""
    __tablename__ = "trading_journal"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    account_id = Column(Integer, nullable=False)
    position_ticket = Column(String(100), nullable=True)
    instrument = Column(String(50), nullable=False)
    direction = Column(String(10), nullable=False)
    
    entry_price = Column(Float, nullable=False)
    exit_price = Column(Float, nullable=False)
    pnl = Column(Float, nullable=False)
    pnl_pct = Column(Float, nullable=False)
    lots = Column(Float, nullable=False)
    holding_time_minutes = Column(Integer, default=0)
    
    strategy_used = Column(String(100), nullable=False)
    risk_settings_snapshot_json = Column(Text, nullable=True)
    ai_explanation = Column(Text, nullable=False)
    lessons_learned = Column(Text, nullable=True)
    user_notes = Column(Text, nullable=True)
    tags_json = Column(String(255), default="[]")
    
    created_at = Column(DateTime, default=datetime.utcnow)
    user = relationship("User", back_populates="journal_entries")

class Strategy(Base):
    """Custom and Built-in AI Trading Strategies."""
    __tablename__ = "strategies"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    name = Column(String(100), nullable=False)
    code_identifier = Column(String(100), unique=True, nullable=False)
    description = Column(Text, nullable=True)
    parameters_json = Column(Text, nullable=False) # Configurable params
    is_active = Column(Boolean, default=True)
    
    win_rate = Column(Float, default=0.0)
    total_trades = Column(Integer, default=0)
    profit_factor = Column(Float, default=0.0)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    user = relationship("User", back_populates="strategies")

class AuditLog(Base):
    """Immutable audit trail for risk events, trade executions, and emergency actions."""
    __tablename__ = "audit_logs"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, nullable=True)
    account_id = Column(Integer, nullable=True)
    event_type = Column(String(100), nullable=False) # RISK_BREACH, EMERGENCY_ACTION, TRADE_EXECUTION, etc.
    action = Column(String(100), nullable=False)
    details_json = Column(Text, nullable=False)
    timestamp = Column(DateTime, default=datetime.utcnow)

# Database Engine & Session Provider
engine = create_engine(
    settings.DATABASE_URL, 
    connect_args={"check_same_thread": False} if "sqlite" in settings.DATABASE_URL else {}
)
SessionLocal = scoped_session(sessionmaker(autocommit=False, autoflush=False, bind=engine))

def init_db():
    Base.metadata.create_all(bind=engine)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

