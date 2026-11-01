"""TD TRADER - Unified Order Execution & Broker Confirmation Pipeline
Orchestrates trade validation via Smart Risk Guardian, routes to MT4/MT5 Bridge or Paper Engine,
and enforces strict broker confirmation receipts before updating internal state.
"""

from typing import Dict, Any, Optional
from datetime import datetime
import uuid
from td_trader.backend.app.models.entities import TradingAccount, RiskConfiguration, Order, Position, AuditLog
from td_trader.backend.app.schemas.schemas import OrderSubmitRequest
from td_trader.ai_engine.risk_engine.risk_guardian import smart_risk_guardian
from td_trader.ai_engine.market_scanner.market_data_feed import market_data_feed
from td_trader.metatrader_bridge.connectors.bridge_connector import bridge_connector
from td_trader.backend.app.services.paper_trading_service import paper_trading_engine
from td_trader.ai_engine.voice_engine.voice_service import td_ai_voice_engine

class OrderExecutionService:
    """Enterprise execution service. Guarantees safe routing, risk enforcement, and receipt logging."""
    
    @staticmethod
    def execute_order(db_session, req: OrderSubmitRequest) -> Dict[str, Any]:
        account = db_session.query(TradingAccount).filter(TradingAccount.id == req.account_id).first()
        if not account:
            raise ValueError(f"Trading account ID {req.account_id} not found.")
            
        risk_cfg = db_session.query(RiskConfiguration).filter(RiskConfiguration.account_id == account.id).first()
        if not risk_cfg:
            raise ValueError(f"Risk configuration not initialized for account {account.id}")
            
        # 1. Fetch live market quote for entry baseline
        quote = market_data_feed.get_latest_quote(req.instrument)
        if not quote:
            raise ValueError(f"Market quote unavailable for {req.instrument}")
            
        entry_price = quote["ask"] if req.direction.upper() == "BUY" else quote["bid"]
        
        # 2. Dynamic Position Sizing (if not explicitly specified)
        lots = req.lots
        if lots is None or lots <= 0:
            lots = smart_risk_guardian.calculate_lot_size(
                equity=account.equity,
                risk_pct=risk_cfg.risk_per_trade_pct,
                entry_price=entry_price,
                stop_loss=req.stop_loss,
                symbol=req.instrument,
                max_lot_size=risk_cfg.max_lot_size
            )
            
        # 3. Independent Pre-Trade Risk Gate Validation
        open_positions = db_session.query(Position).filter(
            Position.account_id == account.id,
            Position.status == "OPEN"
        ).all()
        
        is_approved, gate_reason = smart_risk_guardian.validate_pre_trade_gates(
            account=account,
            risk_cfg=risk_cfg,
            symbol=req.instrument,
            direction=req.direction.upper(),
            lots=lots,
            entry_price=entry_price,
            stop_loss=req.stop_loss,
            take_profit=req.take_profit,
            open_positions=open_positions
        )
        
        if not is_approved:
            # Record audit log of rejection
            audit = AuditLog(
                user_id=account.user_id,
                account_id=account.id,
                event_type="ORDER_REJECTED_BY_RISK_GUARDIAN",
                action="BLOCK_EXECUTION",
                details_json=f'{{"reason": "{gate_reason}", "instrument": "{req.instrument}", "lots": {lots}}}',
                timestamp=datetime.utcnow()
            )
            db_session.add(audit)
            db_session.commit()
            raise PermissionError(f"Smart Risk Guardian Block: {gate_reason}")

        # 4. Route to Execution Destination
        client_oid = str(uuid.uuid4())
        
        # CASE A: Paper Trading Sandbox
        if account.platform == "PAPER_TRADING":
            result = paper_trading_engine.execute_paper_order(
                db_session=db_session,
                account=account,
                symbol=req.instrument,
                direction=req.direction.upper(),
                lots=lots,
                stop_loss=req.stop_loss,
                take_profit=req.take_profit,
                signal_id=req.signal_id
            )
            return result
            
        # CASE B: MetaTrader 4 / MetaTrader 5 Terminal Execution
        order_payload = {
            "client_order_id": client_oid,
            "instrument": req.instrument,
            "direction": req.direction.upper(),
            "lots": lots,
            "requested_price": entry_price,
            "stop_loss": req.stop_loss,
            "take_profit": req.take_profit,
            "signal_id": req.signal_id
        }
        
        broker_receipt = bridge_connector.dispatch_order_to_terminal(account, order_payload)
        
        if not broker_receipt.get("confirmed", False):
            raise RuntimeError(f"Broker rejected execution: {broker_receipt.get('error', 'Unknown Error')}")
            
        # Order CONFIRMED by broker: persist records
        ticket = broker_receipt["broker_ticket"]
        fill_price = broker_receipt["fill_price"]
        slippage = broker_receipt.get("slippage_pips", 0.0)
        commission = round(lots * 5.5, 2)
        
        order = Order(
            client_order_id=client_oid,
            broker_ticket=ticket,
            account_id=account.id,
            signal_id=req.signal_id,
            instrument=req.instrument,
            order_type=req.direction.upper(),
            requested_lots=lots,
            filled_lots=lots,
            requested_price=entry_price,
            fill_price=fill_price,
            slippage_pips=slippage,
            stop_loss=req.stop_loss,
            take_profit=req.take_profit,
            commission=commission,
            swap=0.0,
            status="CONFIRMED",
            broker_confirmation_timestamp=datetime.utcnow(),
            created_at=datetime.utcnow()
        )
        db_session.add(order)
        
        pos = Position(
            position_ticket=ticket,
            account_id=account.id,
            signal_id=req.signal_id,
            instrument=req.instrument,
            direction=req.direction.upper(),
            lots=lots,
            open_price=fill_price,
            current_price=fill_price,
            stop_loss=req.stop_loss,
            take_profit=req.take_profit,
            floating_pnl=-commission,
            realized_pnl=0.0,
            commission=commission,
            status="OPEN",
            open_time=datetime.utcnow()
        )
        db_session.add(pos)
        db_session.commit()
        
        voice = td_ai_voice_engine.create_trade_execution_announcement(req.instrument, req.direction.lower())
        
        return {
            "ticket": ticket,
            "status": "CONFIRMED_BY_BROKER",
            "fill_price": fill_price,
            "lots": lots,
            "slippage_pips": slippage,
            "commission": commission,
            "voice_announcement": voice.message
        }

order_execution_service = OrderExecutionService()

