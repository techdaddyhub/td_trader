-- TD TRADER - Relational SQL Schema Definition
-- Compatible with PostgreSQL 14+ and SQLite 3.35+

CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    email VARCHAR(255) UNIQUE NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    hashed_password VARCHAR(255) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    is_superuser BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS trading_accounts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    account_number VARCHAR(100) NOT NULL,
    broker_name VARCHAR(100) NOT NULL,
    server VARCHAR(150) NOT NULL,
    platform VARCHAR(50) NOT NULL, -- MT4_DEMO, MT4_LIVE, MT5_DEMO, MT5_LIVE, PAPER_TRADING
    currency VARCHAR(10) DEFAULT 'USD',
    encrypted_credentials TEXT,   -- AES-256 Fernet Encrypted
    balance DOUBLE PRECISION DEFAULT 10000.0,
    equity DOUBLE PRECISION DEFAULT 10000.0,
    free_margin DOUBLE PRECISION DEFAULT 10000.0,
    used_margin DOUBLE PRECISION DEFAULT 0.0,
    floating_pnl DOUBLE PRECISION DEFAULT 0.0,
    connection_status VARCHAR(50) DEFAULT 'CONNECTED',
    is_auto_trading_enabled BOOLEAN DEFAULT FALSE,
    is_authorized_live BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS risk_configurations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    account_id INTEGER UNIQUE NOT NULL REFERENCES trading_accounts(id) ON DELETE CASCADE,
    risk_per_trade_pct DOUBLE PRECISION DEFAULT 1.0,
    max_daily_loss_pct DOUBLE PRECISION DEFAULT 3.0,
    max_daily_loss_amount DOUBLE PRECISION DEFAULT 300.0,
    max_daily_drawdown_pct DOUBLE PRECISION DEFAULT 4.0,
    max_account_drawdown_pct DOUBLE PRECISION DEFAULT 8.0,
    max_open_trades INTEGER DEFAULT 5,
    max_correlated_exposure INTEGER DEFAULT 2,
    max_lot_size DOUBLE PRECISION DEFAULT 5.0,
    consecutive_loss_limit INTEGER DEFAULT 3,
    current_consecutive_losses INTEGER DEFAULT 0,
    daily_starting_equity DOUBLE PRECISION DEFAULT 10000.0,
    current_daily_loss DOUBLE PRECISION DEFAULT 0.0,
    is_risk_guardian_tripped BOOLEAN DEFAULT FALSE,
    trip_reason VARCHAR(255),
    auto_liquidate_on_breach BOOLEAN DEFAULT FALSE,
    restrict_on_high_impact_news BOOLEAN DEFAULT TRUE,
    allowed_sessions VARCHAR(255) DEFAULT 'LONDON,NEW_YORK,TOKYO',
    emergency_paused BOOLEAN DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS signals (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    instrument VARCHAR(50) NOT NULL,
    market_category VARCHAR(50) NOT NULL,
    direction VARCHAR(10) NOT NULL,
    timeframe VARCHAR(10) NOT NULL,
    entry_price DOUBLE PRECISION NOT NULL,
    stop_loss DOUBLE PRECISION NOT NULL,
    take_profit_1 DOUBLE PRECISION NOT NULL,
    take_profit_2 DOUBLE PRECISION,
    take_profit_3 DOUBLE PRECISION,
    risk_reward_ratio DOUBLE PRECISION NOT NULL,
    score DOUBLE PRECISION NOT NULL,
    score_breakdown_json TEXT NOT NULL,
    strategy_name VARCHAR(100) NOT NULL,
    market_structure VARCHAR(100) NOT NULL,
    status VARCHAR(50) DEFAULT 'ACTIVE',
    ai_rationale TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP
);

CREATE TABLE IF NOT EXISTS orders (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    client_order_id VARCHAR(100) UNIQUE NOT NULL,
    broker_ticket VARCHAR(100),
    account_id INTEGER NOT NULL REFERENCES trading_accounts(id) ON DELETE CASCADE,
    signal_id INTEGER REFERENCES signals(id),
    instrument VARCHAR(50) NOT NULL,
    order_type VARCHAR(20) NOT NULL,
    requested_lots DOUBLE PRECISION NOT NULL,
    filled_lots DOUBLE PRECISION DEFAULT 0.0,
    requested_price DOUBLE PRECISION NOT NULL,
    fill_price DOUBLE PRECISION,
    slippage_pips DOUBLE PRECISION DEFAULT 0.0,
    stop_loss DOUBLE PRECISION,
    take_profit DOUBLE PRECISION,
    commission DOUBLE PRECISION DEFAULT 0.0,
    swap DOUBLE PRECISION DEFAULT 0.0,
    status VARCHAR(50) DEFAULT 'SUBMITTED',
    error_message TEXT,
    broker_confirmation_timestamp TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS positions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    position_ticket VARCHAR(100) UNIQUE NOT NULL,
    account_id INTEGER NOT NULL REFERENCES trading_accounts(id) ON DELETE CASCADE,
    signal_id INTEGER REFERENCES signals(id),
    instrument VARCHAR(50) NOT NULL,
    direction VARCHAR(10) NOT NULL,
    lots DOUBLE PRECISION NOT NULL,
    open_price DOUBLE PRECISION NOT NULL,
    current_price DOUBLE PRECISION NOT NULL,
    close_price DOUBLE PRECISION,
    stop_loss DOUBLE PRECISION,
    take_profit DOUBLE PRECISION,
    floating_pnl DOUBLE PRECISION DEFAULT 0.0,
    realized_pnl DOUBLE PRECISION DEFAULT 0.0,
    commission DOUBLE PRECISION DEFAULT 0.0,
    swap DOUBLE PRECISION DEFAULT 0.0,
    status VARCHAR(20) DEFAULT 'OPEN',
    close_reason VARCHAR(100),
    open_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    close_time TIMESTAMP
);

CREATE TABLE IF NOT EXISTS trading_journal (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    account_id INTEGER NOT NULL,
    position_ticket VARCHAR(100),
    instrument VARCHAR(50) NOT NULL,
    direction VARCHAR(10) NOT NULL,
    entry_price DOUBLE PRECISION NOT NULL,
    exit_price DOUBLE PRECISION NOT NULL,
    pnl DOUBLE PRECISION NOT NULL,
    pnl_pct DOUBLE PRECISION NOT NULL,
    lots DOUBLE PRECISION NOT NULL,
    holding_time_minutes INTEGER DEFAULT 0,
    strategy_used VARCHAR(100) NOT NULL,
    risk_settings_snapshot_json TEXT,
    ai_explanation TEXT NOT NULL,
    lessons_learned TEXT,
    user_notes TEXT,
    tags_json VARCHAR(255) DEFAULT '[]',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS audit_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER,
    account_id INTEGER,
    event_type VARCHAR(100) NOT NULL,
    action VARCHAR(100) NOT NULL,
    details_json TEXT NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

