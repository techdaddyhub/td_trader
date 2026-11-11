"""TD TRADER - Comprehensive REST API Endpoints
Implements routing for Authentication, Multi-Market Scanner, TD AI Voice,
Smart Risk Guardian, Backtesting Lab, Multi-Account Manager, and Trading Journal.
"""

import json
from typing import List, Dict, Any, Optional
from datetime import datetime
from starlette.requests import Request
from starlette.responses import JSONResponse, Response
from starlette.routing import Route, Mount, WebSocketRoute
from starlette.websockets import WebSocket, WebSocketDisconnect

from td_trader.backend.app.models.entities import (
    SessionLocal, User, TradingAccount, RiskConfiguration, Signal, Order, Position,
    TradingJournalEntry, Strategy, AuditLog
)
from td_trader.backend.app.core.security import (
    hash_password, verify_password, create_access_token, verify_access_token,
    encrypt_broker_credential
)
from td_trader.ai_engine.market_scanner.scanner import ai_market_scanner
from td_trader.ai_engine.market_scanner.market_data_feed import market_data_feed, INSTRUMENT_CATALOG
from td_trader.ai_engine.voice_engine.voice_service import td_ai_voice_engine, VOICE_PERSONALITIES
from td_trader.ai_engine.risk_engine.risk_guardian import smart_risk_guardian
from td_trader.backtesting.simulation.engine import backtest_engine
from td_trader.backtesting.walk_forward.walk_forward import WalkForwardAnalyzer
from td_trader.ai_engine.strategy_engine.strategies import STRATEGY_REGISTRY
from td_trader.metatrader_bridge.account_sync.sync_service import account_sync_service
from td_trader.metatrader_bridge.execution.execution_service import order_execution_service
from td_trader.backend.app.services.paper_trading_service import paper_trading_engine
from td_trader.backend.app.services.deriv_connector import deriv_connector
from td_trader.backend.app.schemas.schemas import (
    UserCreate, UserLogin, TradingAccountCreate, DerivTokenVerifyRequest, RiskConfigUpdate,
    EmergencyActionRequest, ScannerFilterParams, OrderSubmitRequest, BacktestRequest,
    VoiceQueryRequest, JournalEntryCreate
)
from td_trader.backend.app.websocket.connection_manager import ws_manager

# --- Authentication Helpers ---
def get_current_user_from_request(request: Request, db) -> Optional[User]:
    auth_header = request.headers.get("Authorization")
    if not auth_header or not auth_header.startswith("Bearer "):
        return None
    token = auth_header.split(" ")[1]
    payload = verify_access_token(token)
    if not payload:
        return None
    user_id = payload.get("user_id")
    return db.query(User).filter(User.id == user_id).first()

# --- Auth Endpoints ---
async def register_user(request: Request):
    data = await request.json()
    req = UserCreate(**data)
    db = SessionLocal()
    try:
        existing = db.query(User).filter(User.email == req.email).first()
        if existing:
            return JSONResponse({"detail": "User with this email already exists"}, status_code=400)
            
        hashed = hash_password(req.password)
        user = User(email=req.email, full_name=req.full_name, hashed_password=hashed)
        db.add(user)
        db.commit()
        db.refresh(user)
        
        # Create default Paper Trading account for safe immediate exploration
        paper_acct = TradingAccount(
            user_id=user.id,
            account_number="PAPER-1001",
            broker_name="TD Trader Simulated Broker",
            server="TD-Paper-Server-01",
            platform="PAPER_TRADING",
            currency="USD",
            balance=10000.0,
            equity=10000.0,
            free_margin=10000.0,
            is_auto_trading_enabled=True,
            is_authorized_live=False,
            connection_status="CONNECTED"
        )
        db.add(paper_acct)
        db.commit()
        db.refresh(paper_acct)
        
        # Create default Risk Configuration
        risk_cfg = RiskConfiguration(
            account_id=paper_acct.id,
            daily_starting_equity=10000.0
        )
        db.add(risk_cfg)
        db.commit()
        
        token = create_access_token({"user_id": user.id, "email": user.email, "role": "trader"})
        return JSONResponse({
            "access_token": token,
            "token_type": "bearer",
            "user_id": user.id,
            "full_name": user.full_name,
            "email": user.email
        })
    finally:
        db.close()

async def login_user(request: Request):
    data = await request.json()
    req = UserLogin(**data)
    db = SessionLocal()
    try:
        user = db.query(User).filter(User.email == req.email).first()
        if not user or not verify_password(req.password, user.hashed_password):
            return JSONResponse({"detail": "Invalid email or password credentials"}, status_code=401)
            
        token = create_access_token({"user_id": user.id, "email": user.email, "role": "trader"})
        return JSONResponse({
            "access_token": token,
            "token_type": "bearer",
            "user_id": user.id,
            "full_name": user.full_name,
            "email": user.email
        })
    finally:
        db.close()

async def get_current_user_profile(request: Request):
    db = SessionLocal()
    try:
        user = get_current_user_from_request(request, db)
        if not user:
            return JSONResponse({"detail": "Unauthorized"}, status_code=401)
        return JSONResponse({
            "id": user.id,
            "email": user.email,
            "full_name": user.full_name,
            "is_active": user.is_active,
            "created_at": user.created_at.isoformat()
        })
    finally:
        db.close()

# --- MODULE 1: AI Multi-Market Scanner Endpoints ---
async def get_scanner_opportunities(request: Request):
    q_params = request.query_params
    filt = ScannerFilterParams(
        market_category=q_params.get("category"),
        instrument=q_params.get("instrument"),
        timeframe=q_params.get("timeframe"),
        direction=q_params.get("direction"),
        strategy=q_params.get("strategy"),
        min_score=float(q_params.get("min_score", 60.0))
    )
    opps = ai_market_scanner.get_filtered_opportunities(filt)
    return JSONResponse([o.model_dump(mode="json") for o in opps])

async def trigger_scanner_refresh(request: Request):
    opps = ai_market_scanner.scan_all_markets()
    # Broadcast to WebSocket subscribers
    if opps:
        await ws_manager.broadcast_event("NEW_MARKET_SIGNAL", opps[0].model_dump(mode="json"))
    return JSONResponse({
        "status": "SCAN_COMPLETE",
        "total_opportunities": len(opps),
        "timestamp": datetime.utcnow().isoformat(),
        "top_ranked": opps[:5] if opps else []
    })

async def get_live_quotes(request: Request):
    quotes = market_data_feed.get_all_quotes()
    return JSONResponse(quotes)

async def get_ohlcv_data(request: Request):
    symbol = request.path_params["symbol"].upper()
    tf = request.query_params.get("timeframe", "H1").upper()
    try:
        df = market_data_feed.get_ohlcv(symbol, tf)
        records = df.reset_index().to_dict(orient="records")
        for r in records:
            r["index"] = str(r["index"])
        return JSONResponse({"symbol": symbol, "timeframe": tf, "candles": records})
    except Exception as e:
        return JSONResponse({"detail": str(e)}, status_code=400)

# --- MODULE 2: TD AI Voice Endpoints ---
async def voice_query_handler(request: Request):
    data = await request.json()
    req = VoiceQueryRequest(**data)
    db = SessionLocal()
    try:
        user = get_current_user_from_request(request, db)
        user_id = user.id if user else 1
        
        # Fetch verified account and risk context
        acct = db.query(TradingAccount).filter(TradingAccount.user_id == user_id).first()
        risk_cfg = db.query(RiskConfiguration).filter(RiskConfiguration.account_id == acct.id).first() if acct else None
        open_pos = db.query(Position).filter(Position.account_id == acct.id, Position.status == "OPEN").all() if acct else []
        
        ctx = {
            "account": {
                "balance": acct.balance if acct else 10000.0,
                "equity": acct.equity if acct else 10000.0,
                "floating_pnl": acct.floating_pnl if acct else 0.0
            },
            "risk": {
                "current_daily_loss": risk_cfg.current_daily_loss if risk_cfg else 0.0,
                "max_daily_loss_pct": risk_cfg.max_daily_loss_pct if risk_cfg else 3.0,
                "is_risk_guardian_tripped": risk_cfg.is_risk_guardian_tripped if risk_cfg else False,
                "current_consecutive_losses": risk_cfg.current_consecutive_losses if risk_cfg else 0
            },
            "positions": [{"position_ticket": p.position_ticket, "instrument": p.instrument, "direction": p.direction, "open_price": p.open_price, "current_price": p.current_price, "floating_pnl": p.floating_pnl} for p in open_pos]
        }
        
        res = td_ai_voice_engine.process_conversation(req, ctx)
        return JSONResponse(res.model_dump())
    finally:
        db.close()

async def get_voice_personalities(request: Request):
    return JSONResponse(VOICE_PERSONALITIES)

async def test_voice_announcement(request: Request):
    atype = request.path_params["type"].upper()
    if atype == "NEW_SIGNAL":
        ann = td_ai_voice_engine.create_new_signal_announcement("XAUUSD", "BUY", "bullish")
    elif atype == "TRADE_EXECUTION":
        ann = td_ai_voice_engine.create_trade_execution_announcement("EURUSD", "buy")
    elif atype == "TRADE_CLOSURE":
        ann = td_ai_voice_engine.create_trade_closure_announcement()
    elif atype == "MARKET_ALERT":
        ann = td_ai_voice_engine.create_market_alert_announcement("Gold")
    elif atype == "RISK_ALERT":
        ann = td_ai_voice_engine.create_risk_alert_announcement()
    else:
        return JSONResponse({"detail": f"Unknown announcement type {atype}"}, status_code=400)
    return JSONResponse(ann.model_dump(mode="json"))

# --- MODULE 3: Smart Risk Guardian Endpoints ---
async def get_risk_config(request: Request):
    account_id = int(request.path_params["account_id"])
    db = SessionLocal()
    try:
        cfg = db.query(RiskConfiguration).filter(RiskConfiguration.account_id == account_id).first()
        if not cfg:
            return JSONResponse({"detail": "Risk config not found"}, status_code=404)
        return JSONResponse({
            "id": cfg.id,
            "account_id": cfg.account_id,
            "risk_per_trade_pct": cfg.risk_per_trade_pct,
            "max_daily_loss_pct": cfg.max_daily_loss_pct,
            "max_daily_loss_amount": cfg.max_daily_loss_amount,
            "max_daily_drawdown_pct": cfg.max_daily_drawdown_pct,
            "max_account_drawdown_pct": cfg.max_account_drawdown_pct,
            "max_open_trades": cfg.max_open_trades,
            "max_correlated_exposure": cfg.max_correlated_exposure,
            "max_lot_size": cfg.max_lot_size,
            "consecutive_loss_limit": cfg.consecutive_loss_limit,
            "current_consecutive_losses": cfg.current_consecutive_losses,
            "current_daily_loss": cfg.current_daily_loss,
            "is_risk_guardian_tripped": cfg.is_risk_guardian_tripped,
            "trip_reason": cfg.trip_reason,
            "auto_liquidate_on_breach": cfg.auto_liquidate_on_breach,
            "restrict_on_high_impact_news": cfg.restrict_on_high_impact_news,
            "emergency_paused": cfg.emergency_paused
        })
    finally:
        db.close()

async def update_risk_config(request: Request):
    account_id = int(request.path_params["account_id"])
    data = await request.json()
    req = RiskConfigUpdate(**data)
    db = SessionLocal()
    try:
        cfg = db.query(RiskConfiguration).filter(RiskConfiguration.account_id == account_id).first()
        if not cfg:
            return JSONResponse({"detail": "Risk config not found"}, status_code=404)
        for field, val in req.model_dump(exclude_unset=True).items():
            setattr(cfg, field, val)
        db.commit()
        return JSONResponse({"status": "SUCCESS", "message": "Risk configuration updated"})
    finally:
        db.close()

async def execute_emergency_control(request: Request):
    account_id = int(request.path_params["account_id"])
    data = await request.json()
    req = EmergencyActionRequest(**data)
    db = SessionLocal()
    try:
        acct = db.query(TradingAccount).filter(TradingAccount.id == account_id).first()
        cfg = db.query(RiskConfiguration).filter(RiskConfiguration.account_id == account_id).first()
        if not acct or not cfg:
            return JSONResponse({"detail": "Account or Risk config not found"}, status_code=404)
            
        res = smart_risk_guardian.execute_emergency_action(db, acct, cfg, req)
        await ws_manager.broadcast_event("RISK_LIMIT_REACHED", res)
        return JSONResponse(res)
    except Exception as e:
        return JSONResponse({"detail": str(e)}, status_code=400)
    finally:
        db.close()

# --- MODULE 4: AI Strategy Lab & Backtesting Endpoints ---
async def run_backtest_handler(request: Request):
    data = await request.json()
    req = BacktestRequest(**data)
    try:
        res = backtest_engine.run_backtest(req)
        return JSONResponse(res.model_dump(mode="json"))
    except Exception as e:
        return JSONResponse({"detail": str(e)}, status_code=400)

async def compare_strategies_handler(request: Request):
    data = await request.json()
    symbol = data.get("instrument", "EURUSD")
    strategies = data.get("strategies", ["MA_Crossover", "RSI_Dynamic_Reversal", "MACD_Momentum", "Bollinger_Squeeze_Breakout", "Supertrend_Structure_Confluence"])
    tf = data.get("timeframe", "H1")
    res = backtest_engine.compare_strategies(symbol, strategies, tf)
    return JSONResponse(res)

async def list_available_strategies(request: Request):
    return JSONResponse(list(STRATEGY_REGISTRY.keys()))

# --- MODULE 5: Multi-Account Manager & Trading Endpoints ---
async def list_trading_accounts(request: Request):
    db = SessionLocal()
    try:
        user = get_current_user_from_request(request, db)
        user_id = user.id if user else 1
        accounts = db.query(TradingAccount).filter(TradingAccount.user_id == user_id).all()
        result = []
        for a in accounts:
            result.append({
                "id": a.id,
                "account_number": a.account_number,
                "broker_name": a.broker_name,
                "server": a.server,
                "platform": a.platform,
                "currency": a.currency,
                "balance": a.balance,
                "equity": a.equity,
                "free_margin": a.free_margin,
                "used_margin": a.used_margin,
                "floating_pnl": a.floating_pnl,
                "connection_status": a.connection_status,
                "is_auto_trading_enabled": a.is_auto_trading_enabled,
                "is_authorized_live": a.is_authorized_live
            })
        return JSONResponse(result)
    finally:
        db.close()

async def create_trading_account(request: Request):
    data = await request.json()
    req = TradingAccountCreate(**data)
    db = SessionLocal()
    try:
        user = get_current_user_from_request(request, db)
        user_id = user.id if user else 1
        
        # Encrypt password with AES-256 Fernet immediately
        encrypted_cred = encrypt_broker_credential(req.password)
        
        acct = TradingAccount(
            user_id=user_id,
            account_number=req.account_number,
            broker_name=req.broker_name,
            server=req.server,
            platform=req.platform,
            currency=req.currency,
            encrypted_credentials=encrypted_cred,
            balance=req.balance,
            equity=req.balance,
            free_margin=req.balance,
            is_auto_trading_enabled=req.is_auto_trading_enabled,
            is_authorized_live=req.is_authorized_live
        )
        db.add(acct)
        db.commit()
        db.refresh(acct)
        
        # Initialize risk config for account
        risk_cfg = RiskConfiguration(
            account_id=acct.id,
            daily_starting_equity=req.balance
        )
        db.add(risk_cfg)
        db.commit()
        
        return JSONResponse({"id": acct.id, "status": "CONNECTED", "message": "Account connected successfully"})
    finally:
        db.close()

async def toggle_auto_trading(request: Request):
    account_id = int(request.path_params["id"])
    data = await request.json()
    enabled = bool(data.get("enabled", False))
    db = SessionLocal()
    try:
        acct = db.query(TradingAccount).filter(TradingAccount.id == account_id).first()
        if not acct:
            return JSONResponse({"detail": "Account not found"}, status_code=404)
        if "LIVE" in acct.platform and enabled and not acct.is_authorized_live:
            return JSONResponse({"detail": "Live account requires explicit live trading authorization first"}, status_code=403)
        acct.is_auto_trading_enabled = enabled
        db.commit()
        return JSONResponse({"status": "SUCCESS", "is_auto_trading_enabled": enabled})
    finally:
        db.close()

async def authorize_live_account(request: Request):
    account_id = int(request.path_params["id"])
    data = await request.json()
    authorized = bool(data.get("authorized", False))
    db = SessionLocal()
    try:
        acct = db.query(TradingAccount).filter(TradingAccount.id == account_id).first()
        if not acct:
            return JSONResponse({"detail": "Account not found"}, status_code=404)
        acct.is_authorized_live = authorized
        db.commit()
        return JSONResponse({"status": "SUCCESS", "is_authorized_live": authorized})
    finally:
        db.close()

async def get_portfolio_summary_handler(request: Request):
    db = SessionLocal()
    try:
        user = get_current_user_from_request(request, db)
        user_id = user.id if user else 1
        summary = account_sync_service.get_portfolio_summary(db, user_id)
        return JSONResponse(summary.model_dump())
    finally:
        db.close()

async def submit_order_handler(request: Request):
    data = await request.json()
    req = OrderSubmitRequest(**data)
    db = SessionLocal()
    try:
        res = await order_execution_service.execute_order_async(db, req)
        await ws_manager.broadcast_event("ORDER_CONFIRMED", res)
        return JSONResponse(res)
    except Exception as e:
        return JSONResponse({"detail": str(e)}, status_code=400)
    finally:
        db.close()

async def get_positions_handler(request: Request):
    account_id = int(request.path_params["account_id"])
    db = SessionLocal()
    try:
        # Update mark-to-market prices
        paper_trading_engine.update_positions_mark_to_market(db, account_id)
        positions = db.query(Position).filter(Position.account_id == account_id, Position.status == "OPEN").all()
        res = []
        for p in positions:
            res.append({
                "id": p.id,
                "position_ticket": p.position_ticket,
                "instrument": p.instrument,
                "direction": p.direction,
                "lots": p.lots,
                "open_price": p.open_price,
                "current_price": p.current_price,
                "stop_loss": p.stop_loss,
                "take_profit": p.take_profit,
                "floating_pnl": p.floating_pnl,
                "open_time": p.open_time.isoformat()
            })
        return JSONResponse(res)
    finally:
        db.close()

async def close_position_handler(request: Request):
    pos_id = int(request.path_params["position_id"])
    db = SessionLocal()
    try:
        pos = db.query(Position).filter(Position.id == pos_id).first()
        if not pos:
            return JSONResponse({"detail": "Position not found"}, status_code=404)
        if pos.position_ticket.startswith("DERIV_"):
            acct = db.query(TradingAccount).filter(TradingAccount.id == pos.account_id).first()
            if acct and acct.platform.startswith("DERIV_API"):
                try:
                    await deriv_connector.close_contract_async(acct, pos.position_ticket)
                except Exception as exc:
                    return JSONResponse({"detail": f"Deriv close failed: {exc}"}, status_code=400)
        res = paper_trading_engine.close_paper_position(db, pos, "MANUAL_USER_CLOSE")
        await ws_manager.broadcast_event("POSITION_CLOSED", res)
        return JSONResponse(res)
    finally:
        db.close()


# --- Deriv Broker Native API Endpoints ---
async def verify_deriv_token_handler(request: Request):
    data = await request.json()
    req = DerivTokenVerifyRequest(**data)
    try:
        profile = await deriv_connector.authorize_token(req.api_token, req.app_id)
        return JSONResponse(profile)
    except Exception as e:
        return JSONResponse({"detail": str(e)}, status_code=400)


async def list_deriv_instruments_handler(request: Request):
    return JSONResponse(deriv_connector.get_supported_instruments())


async def sync_deriv_market_data_handler(request: Request):
    try:
        data = await request.json() if await request.body() else {}
    except Exception:
        data = {}
    app_id = str(data.get("app_id", "1089"))
    requested_symbols = data.get("symbols") or ["V75", "V100", "BOOM1000", "CRASH1000", "STEP"]
    synced = []
    errors = []
    for sym in requested_symbols:
        try:
            tick = await deriv_connector.fetch_live_tick(sym, app_id=app_id)
            synced.append(tick)
        except Exception as exc:
            errors.append({"symbol": sym, "error": str(exc)})
    return JSONResponse({"synced_count": len(synced), "quotes": synced, "errors": errors})

# --- Trading Journal Endpoints ---
async def list_journal_entries(request: Request):
    db = SessionLocal()
    try:
        entries = db.query(TradingJournalEntry).order_by(TradingJournalEntry.created_at.desc()).all()
        res = []
        for e in entries:
            res.append({
                "id": e.id,
                "account_id": e.account_id,
                "instrument": e.instrument,
                "direction": e.direction,
                "entry_price": e.entry_price,
                "exit_price": e.exit_price,
                "pnl": e.pnl,
                "pnl_pct": e.pnl_pct,
                "lots": e.lots,
                "strategy_used": e.strategy_used,
                "ai_explanation": e.ai_explanation,
                "lessons_learned": e.lessons_learned,
                "user_notes": e.user_notes,
                "created_at": e.created_at.isoformat()
            })
        return JSONResponse(res)
    finally:
        db.close()

# --- WebSocket Route ---
async def websocket_endpoint(websocket: WebSocket):
    user_id = 1
    await ws_manager.connect(websocket, user_id)
    try:
        while True:
            text = await websocket.receive_text()
            data = json.loads(text)
            if data.get("action") == "PING":
                await websocket.send_text(json.dumps({"event": "PONG", "timestamp": datetime.utcnow().isoformat()}))
    except WebSocketDisconnect:
        ws_manager.disconnect(websocket, user_id)
    except Exception:
        ws_manager.disconnect(websocket, user_id)

