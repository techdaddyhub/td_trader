"""TD TRADER - Pydantic Request & Response Schemas
Type-safe data contracts for all 5 core modules, API endpoints, and internal events.
"""

from datetime import datetime
from typing import Optional, List, Dict, Any
from pydantic import BaseModel, Field

# --- Auth & User ---
class UserCreate(BaseModel):
    email: str
    full_name: str
    password: str

class UserLogin(BaseModel):
    email: str
    password: str

class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user_id: int
    full_name: str
    email: str

class UserResponse(BaseModel):
    id: int
    email: str
    full_name: str
    is_active: bool
    created_at: datetime

# --- Trading Account ---
class TradingAccountCreate(BaseModel):
    account_number: str
    broker_name: str
    server: str
    platform: str # MT4_DEMO, MT4_LIVE, MT5_DEMO, MT5_LIVE, DERIV_API_DEMO, DERIV_API_LIVE, PAPER_TRADING
    currency: str = "USD"
    password: str = "" # Master/Investor password OR Deriv API token (encrypted immediately upon receipt)
    balance: float = 10000.0
    is_auto_trading_enabled: bool = False
    is_authorized_live: bool = False


class DerivTokenVerifyRequest(BaseModel):
    api_token: str
    app_id: str = "1089"

class TradingAccountUpdate(BaseModel):
    is_auto_trading_enabled: Optional[bool] = None
    is_authorized_live: Optional[bool] = None
    broker_name: Optional[str] = None
    server: Optional[str] = None

class TradingAccountResponse(BaseModel):
    id: int
    user_id: int
    account_number: str
    broker_name: str
    server: str
    platform: str
    currency: str
    balance: float
    equity: float
    free_margin: float
    used_margin: float
    floating_pnl: float
    connection_status: str
    is_auto_trading_enabled: bool
    is_authorized_live: bool
    created_at: datetime

class PortfolioSummary(BaseModel):
    total_accounts: int
    active_connections: int
    total_balance: float
    total_equity: float
    total_floating_pnl: float
    total_open_positions: int
    aggregated_exposure_by_market: Dict[str, float]
    account_summaries: List[Dict[str, Any]]

# --- Smart Risk Guardian ---
class RiskConfigUpdate(BaseModel):
    risk_per_trade_pct: Optional[float] = None
    max_daily_loss_pct: Optional[float] = None
    max_daily_loss_amount: Optional[float] = None
    max_daily_drawdown_pct: Optional[float] = None
    max_account_drawdown_pct: Optional[float] = None
    max_open_trades: Optional[int] = None
    max_correlated_exposure: Optional[int] = None
    max_lot_size: Optional[float] = None
    consecutive_loss_limit: Optional[int] = None
    auto_liquidate_on_breach: Optional[bool] = None
    restrict_on_high_impact_news: Optional[bool] = None
    emergency_paused: Optional[bool] = None

class RiskConfigResponse(BaseModel):
    id: int
    account_id: int
    risk_per_trade_pct: float
    max_daily_loss_pct: float
    max_daily_loss_amount: float
    max_daily_drawdown_pct: float
    max_account_drawdown_pct: float
    max_open_trades: int
    max_correlated_exposure: int
    max_lot_size: float
    consecutive_loss_limit: int
    current_consecutive_losses: int
    current_daily_loss: float
    is_risk_guardian_tripped: bool
    trip_reason: Optional[str]
    auto_liquidate_on_breach: bool
    restrict_on_high_impact_news: bool
    emergency_paused: bool

class EmergencyActionRequest(BaseModel):
    action: str # PAUSE_AI, RESUME_AI, STOP_NEW_TRADES, CANCEL_PENDING, CLOSE_ALL_POSITIONS
    confirm_close_all: bool = False # Explicit confirmation required for closing open positions

# --- Signals & Scanner ---
class OpportunityScoreBreakdown(BaseModel):
    trend_alignment: float       # Max 20
    technical_confirmation: float# Max 20
    momentum: float              # Max 15
    market_structure: float      # Max 15
    volatility: float            # Max 10
    risk_reward: float           # Max 10
    strategy_validation: float   # Max 10
    total_score: float           # 0 - 100

class SignalResponse(BaseModel):
    id: int
    instrument: str
    market_category: str
    direction: str
    timeframe: str
    entry_price: float
    stop_loss: float
    take_profit_1: float
    take_profit_2: Optional[float]
    take_profit_3: Optional[float]
    risk_reward_ratio: float
    score: float
    score_breakdown: OpportunityScoreBreakdown
    strategy_name: str
    market_structure: str
    status: str
    ai_rationale: str
    created_at: datetime
    is_real_time: bool = True
    data_delay_seconds: int = 0

class ScannerFilterParams(BaseModel):
    market_category: Optional[str] = None
    instrument: Optional[str] = None
    timeframe: Optional[str] = None
    direction: Optional[str] = None
    strategy: Optional[str] = None
    min_score: float = 70.0

# --- Orders & Execution ---
class OrderSubmitRequest(BaseModel):
    account_id: int
    instrument: str
    direction: str # BUY, SELL
    lots: Optional[float] = None # Calculated automatically by Risk Guardian if None
    stop_loss: float
    take_profit: float
    signal_id: Optional[int] = None
    order_type: str = "BUY"

class OrderResponse(BaseModel):
    id: int
    client_order_id: str
    broker_ticket: Optional[str]
    account_id: int
    instrument: str
    order_type: str
    requested_lots: float
    filled_lots: float
    requested_price: float
    fill_price: Optional[float]
    slippage_pips: float
    stop_loss: Optional[float]
    take_profit: Optional[float]
    commission: float
    swap: float
    status: str
    error_message: Optional[str]
    created_at: datetime

class PositionResponse(BaseModel):
    id: int
    position_ticket: str
    account_id: int
    instrument: str
    direction: str
    lots: float
    open_price: float
    current_price: float
    stop_loss: Optional[float]
    take_profit: Optional[float]
    floating_pnl: float
    status: str
    open_time: datetime

# --- TD AI Voice & Conversational Assistant ---
class VoiceQueryRequest(BaseModel):
    query: str
    voice_personality: str = "Aria_Fintech_Pro"
    account_id: Optional[int] = None
    conversation_history: List[Dict[str, str]] = []

class VoiceQueryResponse(BaseModel):
    query: str
    response_text: str
    audio_base64: Optional[str] = None
    ssml_markup: Optional[str] = None
    intent: str
    verified_facts: Dict[str, Any]
    ai_interpretation: str
    voice_personality: str

class VoiceAnnouncement(BaseModel):
    announcement_type: str # NEW_SIGNAL, TRADE_EXECUTION, TRADE_CLOSURE, MARKET_ALERT, RISK_ALERT
    message: str
    timestamp: datetime
    audio_base64: Optional[str] = None

# --- Strategy Lab & Backtesting ---
class BacktestRequest(BaseModel):
    strategy_name: str
    instrument: str
    timeframe: str = "H1"
    start_date: str
    end_date: str
    initial_balance: float = 10000.0
    risk_per_trade_pct: float = 1.0
    spread_pips: float = 1.2
    commission_per_lot: float = 5.0
    slippage_pips: float = 0.5
    parameters: Dict[str, Any] = {}
    run_walk_forward: bool = True

class BacktestResult(BaseModel):
    strategy_name: str
    instrument: str
    timeframe: str
    initial_balance: float
    final_balance: float
    net_profit: float
    gross_profit: float
    gross_loss: float
    total_trades: int
    winning_trades: int
    losing_trades: int
    win_rate: float
    profit_factor: float
    max_drawdown_pct: float
    max_drawdown_amount: float
    sharpe_ratio: float
    expectancy_usd: float
    average_trade_usd: float
    average_holding_time_bars: float
    equity_curve: List[Dict[str, Any]]
    monthly_performance: Dict[str, float]
    walk_forward_metrics: Optional[Dict[str, Any]]
    disclaimer: str = "Historical backtesting results do not guarantee future performance. Realistic trading costs included."

# --- Trading Journal ---
class JournalEntryCreate(BaseModel):
    account_id: int
    position_ticket: Optional[str]
    instrument: str
    direction: str
    entry_price: float
    exit_price: float
    pnl: float
    pnl_pct: float
    lots: float
    strategy_used: str
    holding_time_minutes: int
    user_notes: Optional[str]
    emotional_state: Optional[str]
    tags: List[str] = []

class JournalEntryResponse(BaseModel):
    id: int
    user_id: int
    account_id: int
    instrument: str
    direction: str
    entry_price: float
    exit_price: float
    pnl: float
    pnl_pct: float
    lots: float
    strategy_used: str
    ai_explanation: str
    lessons_learned: str
    user_notes: Optional[str]
    tags: List[str]
    created_at: datetime

