"""TD TRADER - Unified Order Execution & Broker Confirmation Pipeline
Orchestrates trade validation via Smart Risk Guardian, routes to MT4/MT5 Bridge,
Deriv Native WebSocket API, or Paper Engine, and enforces strict broker confirmation receipts.
"""

from typing import Dict, Any, Optional, Tuple
from datetime import datetime
import uuid
from td_trader.backend.app.models.entities import TradingAccount, RiskConfiguration, Order, Position, AuditLog
from td_trader.backend.app.schemas.schemas import OrderSubmitRequest
from td_trader.ai_engine.risk_engine.risk_guardian import smart_risk_guardian
from td_trader.ai_engine.market_scanner.market_data_feed import market_data_feed
from td_trader.metatrader_bridge.connectors.bridge_connector import bridge_connector
from td_trader.backend.app.services.paper_trading_service import paper_trading_engine
from td_trader.backend.app.services.deriv_connector import deriv_connector
from td_trader.ai_engine.voice_engine.voice_service import td_ai_voice_engine


class OrderExecutionService:
    """Enterprise execution service. Guarantees safe routing, risk enforcement, and receipt logging."""

    @staticmethod
    def _prepare_and_validate_order(
        db_session, req: OrderSubmitRequest
    ) -> Tuple[TradingAccount, float, float]:
        """Validate account, risk gates, and compute lot size before routing."""
        account = db_session.query(TradingAccount).filter(TradingAccount.id == req.account_id).first()
        if not account:
            raise ValueError(f"Trading account ID {req.account_id} not found.")

        risk_cfg = db_session.query(RiskConfiguration).filter(RiskConfiguration.account_id == account.id).first()
        if not risk_cfg:
            raise ValueError(f"Risk configuration not initialized for account {account.id}")

        quote = market_data_feed.get_latest_quote(req.instrument)
        if not quote:
            raise ValueError(f"Market quote unavailable for {req.instrument}")

        entry_price = quote["ask"] if req.direction.upper() == "BUY" else quote["bid"]

        lots = req.lots
        if lots is None or lots <= 0:
            lots = smart_risk_guardian.calculate_lot_size(
                equity=account.equity,
                risk_pct=risk_cfg.risk_per_trade_pct,
                entry_price=entry_price,
                stop_loss=req.stop_loss,
                symbol=req.instrument,
                max_lot_size=risk_cfg.max_lot_size,
            )

        open_positions = db_session.query(Position).filter(
            Position.account_id == account.id,
            Position.status == "OPEN",
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
            open_positions=open_positions,
        )

        if not is_approved:
            audit = AuditLog(
                user_id=account.user_id,
                account_id=account.id,
                event_type="ORDER_REJECTED_BY_RISK_GUARDIAN",
                action="BLOCK_EXECUTION",
                details_json=f'{{"reason": "{gate_reason}", "instrument": "{req.instrument}", "lots": {lots}}}',
                timestamp=datetime.utcnow(),
            )
            db_session.add(audit)
            db_session.commit()
            raise PermissionError(f"Smart Risk Guardian Block: {gate_reason}")

        return account, entry_price, lots

    @staticmethod
    def _record_confirmed_broker_order(
        db_session,
        account: TradingAccount,
        req: OrderSubmitRequest,
        client_oid: str,
        entry_price: float,
        lots: float,
        broker_receipt: Dict[str, Any],
    ) -> Dict[str, Any]:
        """Persist confirmed broker execution receipt across Order and Position tables."""
        if not broker_receipt.get("confirmed", False):
            raise RuntimeError(f"Broker rejected execution: {broker_receipt.get('error', 'Unknown Error')}")

        ticket = broker_receipt["broker_ticket"]
        fill_price = broker_receipt["fill_price"]
        slippage = broker_receipt.get("slippage_pips", 0.0)
        commission = 0.0 if account.platform.startswith("DERIV_API") else round(lots * 5.5, 2)

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
            created_at=datetime.utcnow(),
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
            open_time=datetime.utcnow(),
        )
        db_session.add(pos)

        if broker_receipt.get("balance_after") is not None:
            account.balance = float(broker_receipt["balance_after"])
            account.equity = float(broker_receipt["balance_after"])

        db_session.commit()

        voice = td_ai_voice_engine.create_trade_execution_announcement(req.instrument, req.direction.lower())

        return {
            "ticket": ticket,
            "status": "CONFIRMED_BY_BROKER",
            "fill_price": fill_price,
            "lots": lots,
            "slippage_pips": slippage,
            "commission": commission,
            "voice_announcement": voice.message,
        }

    @staticmethod
    def _build_order_payload(client_oid: str, req: OrderSubmitRequest, lots: float, entry_price: float) -> Dict[str, Any]:
        return {
            "client_order_id": client_oid,
            "instrument": req.instrument,
            "direction": req.direction.upper(),
            "lots": lots,
            "requested_price": entry_price,
            "stop_loss": req.stop_loss,
            "take_profit": req.take_profit,
            "signal_id": req.signal_id,
        }

    @staticmethod
    def execute_order(db_session, req: OrderSubmitRequest) -> Dict[str, Any]:
        """Synchronous execution entry point (Paper Trading & MetaTrader 4/5 Bridge)."""
        account, entry_price, lots = OrderExecutionService._prepare_and_validate_order(db_session, req)
        client_oid = str(uuid.uuid4())

        if account.platform == "PAPER_TRADING":
            return paper_trading_engine.execute_paper_order(
                db_session=db_session,
                account=account,
                symbol=req.instrument,
                direction=req.direction.upper(),
                lots=lots,
                stop_loss=req.stop_loss,
                take_profit=req.take_profit,
                signal_id=req.signal_id,
            )

        if account.platform.startswith("DERIV_API"):
            raise RuntimeError("Deriv Native API orders must be executed via execute_order_async.")

        order_payload = OrderExecutionService._build_order_payload(client_oid, req, lots, entry_price)
        broker_receipt = bridge_connector.dispatch_order_to_terminal(account, order_payload)
        return OrderExecutionService._record_confirmed_broker_order(
            db_session, account, req, client_oid, entry_price, lots, broker_receipt
        )

    @staticmethod
    async def execute_order_async(db_session, req: OrderSubmitRequest) -> Dict[str, Any]:
        """Async execution entry point supporting Deriv Native WebSocket API, MT4/MT5 Bridge, and Paper Engine."""
        account, entry_price, lots = OrderExecutionService._prepare_and_validate_order(db_session, req)
        client_oid = str(uuid.uuid4())

        if account.platform == "PAPER_TRADING":
            return paper_trading_engine.execute_paper_order(
                db_session=db_session,
                account=account,
                symbol=req.instrument,
                direction=req.direction.upper(),
                lots=lots,
                stop_loss=req.stop_loss,
                take_profit=req.take_profit,
                signal_id=req.signal_id,
            )

        order_payload = OrderExecutionService._build_order_payload(client_oid, req, lots, entry_price)
        if account.platform.startswith("DERIV_API"):
            broker_receipt = await deriv_connector.dispatch_deriv_order_async(account, order_payload)
        else:
            broker_receipt = bridge_connector.dispatch_order_to_terminal(account, order_payload)

        return OrderExecutionService._record_confirmed_broker_order(
            db_session, account, req, client_oid, entry_price, lots, broker_receipt
        )


order_execution_service = OrderExecutionService()

