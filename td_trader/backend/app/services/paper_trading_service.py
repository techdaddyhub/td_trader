"""TD TRADER - Paper Trading Simulation Engine
Provides a realistic, risk-free execution sandbox strictly isolated from live broker accounts.
Calculates tick-by-tick mark-to-market floating PnL, executes SL/TP fills,
and tracks balance, equity, and margin.
"""

from typing import Dict, Any, List, Optional
from datetime import datetime
import uuid
from td_trader.backend.app.models.entities import TradingAccount, Order, Position, TradingJournalEntry
from td_trader.ai_engine.market_scanner.market_data_feed import market_data_feed, INSTRUMENT_CATALOG
from td_trader.ai_engine.voice_engine.voice_service import td_ai_voice_engine

class PaperTradingEngine:
    """Zero-risk institutional simulated trading sandbox."""
    
    @staticmethod
    def execute_paper_order(
        db_session,
        account: TradingAccount,
        symbol: str,
        direction: str,
        lots: float,
        stop_loss: float,
        take_profit: float,
        signal_id: Optional[int] = None
    ) -> Dict[str, Any]:
        """Executes market order in paper trading environment with simulated slippage and commission."""
        quote = market_data_feed.get_latest_quote(symbol)
        if not quote:
            raise ValueError(f"No market data available for {symbol}")
            
        meta = INSTRUMENT_CATALOG.get(symbol, {"pip_size": 0.0001, "digits": 5})
        pip_size = meta["pip_size"]
        spread_val = quote["spread_pips"] * pip_size
        
        # BUY fills at Ask, SELL fills at Bid
        fill_price = quote["ask"] if direction == "BUY" else quote["bid"]
        ticket = f"PAPER_{uuid.uuid4().hex[:8].upper()}"
        commission = round(lots * 5.0, 2) # $5 per lot round-turn commission
        
        # Create Order record
        order = Order(
            client_order_id=str(uuid.uuid4()),
            broker_ticket=ticket,
            account_id=account.id,
            signal_id=signal_id,
            instrument=symbol,
            order_type=direction,
            requested_lots=lots,
            filled_lots=lots,
            requested_price=fill_price,
            fill_price=fill_price,
            slippage_pips=0.1,
            stop_loss=stop_loss,
            take_profit=take_profit,
            commission=commission,
            swap=0.0,
            status="CONFIRMED",
            broker_confirmation_timestamp=datetime.utcnow(),
            created_at=datetime.utcnow()
        )
        db_session.add(order)
        
        # Create Open Position record
        pos = Position(
            position_ticket=ticket,
            account_id=account.id,
            signal_id=signal_id,
            instrument=symbol,
            direction=direction,
            lots=lots,
            open_price=fill_price,
            current_price=fill_price,
            stop_loss=stop_loss,
            take_profit=take_profit,
            floating_pnl=-commission, # Initially down by commission
            realized_pnl=0.0,
            commission=commission,
            swap=0.0,
            status="OPEN",
            open_time=datetime.utcnow()
        )
        db_session.add(pos)
        
        # Deduct used margin and commission from free margin
        required_margin = lots * 1000.0
        account.used_margin += required_margin
        account.free_margin = max(0.0, account.equity - account.used_margin)
        account.balance -= commission
        account.equity = account.balance + pos.floating_pnl
        
        db_session.commit()
        
        # Announce via AI voice
        voice_announcement = td_ai_voice_engine.create_trade_execution_announcement(symbol, direction.lower())
        
        return {
            "ticket": ticket,
            "instrument": symbol,
            "direction": direction,
            "lots": lots,
            "fill_price": fill_price,
            "commission": commission,
            "status": "FILLED_AND_CONFIRMED",
            "voice_announcement": voice_announcement.message
        }

    @staticmethod
    def update_positions_mark_to_market(db_session, account_id: int):
        """Updates all open paper positions with current market tick prices."""
        open_positions = db_session.query(Position).filter(
            Position.account_id == account_id,
            Position.status == "OPEN"
        ).all()
        
        account = db_session.query(TradingAccount).filter(TradingAccount.id == account_id).first()
        if not account:
            return
            
        total_floating = 0.0
        for pos in open_positions:
            quote = market_data_feed.get_latest_quote(pos.instrument)
            if not quote:
                continue
                
            meta = INSTRUMENT_CATALOG.get(pos.instrument, {"pip_size": 0.0001, "digits": 5, "category": "FOREX"})
            pip_factor = 10.0 if meta.get("category") in ["FOREX", "METALS"] else 1.0
            pip_size = meta["pip_size"]
            
            curr_price = quote["bid"] if pos.direction == "BUY" else quote["ask"]
            pos.current_price = curr_price
            
            # PnL Calculation
            if pos.direction == "BUY":
                pips = (curr_price - pos.open_price) / pip_size
            else:
                pips = (pos.open_price - curr_price) / pip_size
                
            gross_pnl = pips * pos.lots * pip_factor
            pos.floating_pnl = round(gross_pnl - pos.commission, 2)
            total_floating += pos.floating_pnl
            
            # Check Stop Loss breach
            if pos.stop_loss:
                if (pos.direction == "BUY" and curr_price <= pos.stop_loss) or \
                   (pos.direction == "SELL" and curr_price >= pos.stop_loss):
                    PaperTradingEngine.close_paper_position(db_session, pos, "STOP_LOSS")
                    continue
                    
            # Check Take Profit breach
            if pos.take_profit:
                if (pos.direction == "BUY" and curr_price >= pos.take_profit) or \
                   (pos.direction == "SELL" and curr_price <= pos.take_profit):
                    PaperTradingEngine.close_paper_position(db_session, pos, "TAKE_PROFIT")
                    continue
                    
        account.floating_pnl = round(total_floating, 2)
        account.equity = round(account.balance + account.floating_pnl, 2)
        account.free_margin = max(0.0, round(account.equity - account.used_margin, 2))
        db_session.commit()

    @staticmethod
    def close_paper_position(db_session, pos: Position, reason: str = "MANUAL") -> Dict[str, Any]:
        """Closes position, settles realized PnL to balance, and creates Trading Journal entry."""
        account = db_session.query(TradingAccount).filter(TradingAccount.id == pos.account_id).first()
        
        pos.status = "CLOSED"
        pos.close_time = datetime.utcnow()
        pos.close_price = pos.current_price
        pos.close_reason = reason
        pos.realized_pnl = pos.floating_pnl
        
        # Release margin and credit realized PnL to balance
        if account:
            account.balance = round(account.balance + pos.realized_pnl, 2)
            required_margin = pos.lots * 1000.0
            account.used_margin = max(0.0, account.used_margin - required_margin)
            account.equity = round(account.balance, 2)
            account.free_margin = max(0.0, account.equity - account.used_margin)
            
            # Record Trading Journal entry
            holding_time_min = int((pos.close_time - pos.open_time).total_seconds() / 60.0)
            pnl_pct = round((pos.realized_pnl / account.balance) * 100.0, 2) if account.balance > 0 else 0.0
            
            journal = TradingJournalEntry(
                user_id=account.user_id,
                account_id=account.id,
                position_ticket=pos.position_ticket,
                instrument=pos.instrument,
                direction=pos.direction,
                entry_price=pos.open_price,
                exit_price=pos.close_price,
                pnl=pos.realized_pnl,
                pnl_pct=pnl_pct,
                lots=pos.lots,
                holding_time_minutes=holding_time_min,
                strategy_used="AI_Adaptive_Strategy",
                ai_explanation=(
                    f"Position {pos.position_ticket} on {pos.instrument} closed via {reason}. "
                    f"Net result: ${pos.realized_pnl:.2f} ({pnl_pct:+.2f}%). "
                    f"Holding duration was {holding_time_min} minutes."
                ),
                lessons_learned="Disciplined exit adhered to quantitative plan without emotion.",
                user_notes=f"Auto closed by {reason}",
                tags_json='["paper_trading", "automated"]'
            )
            db_session.add(journal)
            
        db_session.commit()
        
        # Voice announcement
        voice = td_ai_voice_engine.create_trade_closure_announcement()
        
        return {
            "ticket": pos.position_ticket,
            "realized_pnl": pos.realized_pnl,
            "close_reason": reason,
            "voice_announcement": voice.message
        }

paper_trading_engine = PaperTradingEngine()

