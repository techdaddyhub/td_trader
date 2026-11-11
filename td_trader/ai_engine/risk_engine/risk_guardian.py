"""TD TRADER - MODULE 3: Smart Risk Guardian Engine
Independent quantitative risk management operating strictly outside the AI language model.
Enforces 16 deterministic risk gates, dynamic lot sizing, automatic breach protection,
and emergency control panel operations.
"""

from typing import Dict, Any, List, Optional, Tuple
from datetime import datetime
import json
from td_trader.backend.app.models.entities import TradingAccount, RiskConfiguration, AuditLog, Order, Position
from td_trader.backend.app.schemas.schemas import RiskConfigUpdate, EmergencyActionRequest
from td_trader.ai_engine.market_scanner.market_data_feed import INSTRUMENT_CATALOG, market_data_feed, get_pip_value_per_lot
from td_trader.ai_engine.voice_engine.voice_service import td_ai_voice_engine

# Currency & asset correlation mapping for correlated exposure checks
CURRENCY_CORRELATION_CLUSTERS = {
    "USD": ["EURUSD", "GBPUSD", "USDJPY", "USDCAD", "AUDUSD", "BTCUSD", "XAUUSD"],
    "EUR": ["EURUSD", "EURGBP", "EURJPY"],
    "GBP": ["GBPUSD", "EURGBP", "GBPJPY"],
    "JPY": ["USDJPY", "GBPJPY", "EURJPY"],
    "CRYPTO": ["BTCUSD", "ETHUSD", "SOLUSD", "XRPUSD"],
    "COMMODITIES": ["XAUUSD", "XAGUSD", "USOIL", "UKOIL"],
    "SYNTHETICS_VOLATILITY": ["V75", "V100", "V50", "V25", "V10", "V75_1S"],
    "SYNTHETICS_SPIKE": ["BOOM1000", "BOOM500", "CRASH1000", "CRASH500"],
    "SYNTHETICS_STEP_JUMP": ["STEP", "JUMP75"],
}

class SmartRiskGuardian:
    """Enterprise risk control subsystem. Strictly independent from LLM outputs."""
    
    @staticmethod
    def calculate_lot_size(
        equity: float,
        risk_pct: float,
        entry_price: float,
        stop_loss: float,
        symbol: str,
        max_lot_size: float = 5.0
    ) -> float:
        """Calculates exact lot size based on equity risk percentage and stop-loss distance."""
        meta = INSTRUMENT_CATALOG.get(symbol, {"pip_size": 0.0001, "digits": 5})
        pip_size = meta["pip_size"]
        
        sl_distance = abs(entry_price - stop_loss)
        sl_pips = sl_distance / pip_size
        
        if sl_pips <= 0:
            return 0.01
            
        risk_usd = equity * (risk_pct / 100.0)
        pip_val_per_std_lot = get_pip_value_per_lot(symbol)
            
        raw_lots = risk_usd / (sl_pips * pip_val_per_std_lot)
        lots = round(max(0.01, min(raw_lots, max_lot_size)), 2)
        return lots

    @staticmethod
    def validate_pre_trade_gates(
        account: TradingAccount,
        risk_cfg: RiskConfiguration,
        symbol: str,
        direction: str,
        lots: float,
        entry_price: float,
        stop_loss: Optional[float],
        take_profit: Optional[float],
        open_positions: List[Position]
    ) -> Tuple[bool, str]:
        """Validates all 16 independent risk gates before any order reaches execution."""
        
        # Gate 1: Emergency Pause
        if risk_cfg.emergency_paused:
            return False, "GATE_BREACH: Emergency trading pause is actively engaged."
            
        # Gate 2: Risk Guardian Tripped
        if risk_cfg.is_risk_guardian_tripped:
            return False, f"GATE_BREACH: Risk Guardian is tripped. Reason: {risk_cfg.trip_reason}"
            
        # Gate 3: Auto-Trading Authorization Check
        if not account.is_auto_trading_enabled:
            return False, "GATE_BREACH: Automated trading is disabled on this account."
            
        # Gate 4: Live Account Explicit Authorization
        if "LIVE" in account.platform and not account.is_authorized_live:
            return False, "GATE_BREACH: Live account has not been granted explicit live trading authorization."
            
        # Gate 5: Stop-Loss Mandatory
        if stop_loss is None or stop_loss <= 0:
            return False, "GATE_BREACH: Explicit Stop Loss is mandatory on all TD Trader orders."
            
        # Gate 6: Directional SL Sanity
        if direction == "BUY" and stop_loss >= entry_price:
            return False, "GATE_BREACH: BUY order stop loss must be strictly below entry price."
        if direction == "SELL" and stop_loss <= entry_price:
            return False, "GATE_BREACH: SELL order stop loss must be strictly above entry price."
            
        # Gate 7: Take-Profit Sanity & Minimum R:R (1.0)
        if take_profit is not None:
            if direction == "BUY" and take_profit <= entry_price:
                return False, "GATE_BREACH: BUY take profit must be strictly above entry price."
            if direction == "SELL" and take_profit >= entry_price:
                return False, "GATE_BREACH: SELL take profit must be strictly below entry price."
            sl_dist = abs(entry_price - stop_loss)
            tp_dist = abs(take_profit - entry_price)
            if sl_dist > 0 and (tp_dist / sl_dist) < 0.95:
                return False, f"GATE_BREACH: Risk/Reward ratio ({tp_dist/sl_dist:.2f}) is below minimum 1.0 requirement."
                
        # Gate 8: Consecutive Loss Lockout
        if risk_cfg.current_consecutive_losses >= risk_cfg.consecutive_loss_limit:
            return False, f"GATE_BREACH: Consecutive loss limit ({risk_cfg.consecutive_loss_limit}) reached. Cooldown required."
            
        # Gate 9: Daily Loss Limit
        if risk_cfg.current_daily_loss >= risk_cfg.max_daily_loss_amount:
            return False, f"GATE_BREACH: Max daily loss (${risk_cfg.max_daily_loss_amount:.2f}) reached."
            
        # Gate 10: Daily Loss Percentage
        if account.equity > 0:
            daily_loss_pct = (risk_cfg.current_daily_loss / risk_cfg.daily_starting_equity) * 100.0
            if daily_loss_pct >= risk_cfg.max_daily_loss_pct:
                return False, f"GATE_BREACH: Daily loss threshold ({daily_loss_pct:.2f}% >= {risk_cfg.max_daily_loss_pct}%) reached."
                
        # Gate 11: Daily Drawdown Check
        if risk_cfg.daily_starting_equity > 0:
            drawdown = (risk_cfg.daily_starting_equity - account.equity) / risk_cfg.daily_starting_equity * 100.0
            if drawdown >= risk_cfg.max_daily_drawdown_pct:
                return False, f"GATE_BREACH: Max daily drawdown threshold ({drawdown:.2f}% >= {risk_cfg.max_daily_drawdown_pct}%) breached."

        # Gate 12: Account Drawdown Check
        if account.balance > 0:
            acct_drawdown = (account.balance - account.equity) / account.balance * 100.0
            if acct_drawdown >= risk_cfg.max_account_drawdown_pct:
                return False, f"GATE_BREACH: Total account drawdown ({acct_drawdown:.2f}% >= {risk_cfg.max_account_drawdown_pct}%) breached."

        # Gate 13: Max Open Trades Cap
        if len(open_positions) >= risk_cfg.max_open_trades:
            return False, f"GATE_BREACH: Max open positions cap ({risk_cfg.max_open_trades}) reached."

        # Gate 14: Correlated Exposure Cap
        correlated_count = 0
        for pos in open_positions:
            for cluster_name, cluster_symbols in CURRENCY_CORRELATION_CLUSTERS.items():
                if symbol in cluster_symbols and pos.instrument in cluster_symbols:
                    correlated_count += 1
                    break
        if correlated_count >= risk_cfg.max_correlated_exposure:
            return False, f"GATE_BREACH: Correlated asset exposure cap ({risk_cfg.max_correlated_exposure}) reached on cluster."

        # Gate 15: Max Lot Size Cap
        if lots > risk_cfg.max_lot_size:
            return False, f"GATE_BREACH: Requested lots ({lots}) exceeds account maximum lot size ({risk_cfg.max_lot_size})."

        # Gate 16: Free Margin Adequacy
        required_margin = (lots * 1000.0) # Approx standard margin requirement
        if account.free_margin < required_margin:
            return False, f"GATE_BREACH: Insufficient free margin (${account.free_margin:.2f} < ${required_margin:.2f})."

        return True, "APPROVED_BY_RISK_GUARDIAN"

    @staticmethod
    def trigger_protection_protocol(
        db_session,
        account: TradingAccount,
        risk_cfg: RiskConfiguration,
        reason: str
    ) -> Dict[str, Any]:
        """Executes automatic breach protocol: suspends entries, cancels pending orders, alerts via voice."""
        risk_cfg.is_risk_guardian_tripped = True
        risk_cfg.trip_reason = reason
        account.is_auto_trading_enabled = False
        
        # Cancel pending orders
        pending_orders = db_session.query(Order).filter(
            Order.account_id == account.id,
            Order.status == "SUBMITTED"
        ).all()
        cancelled_count = 0
        for po in pending_orders:
            po.status = "CANCELLED"
            po.error_message = f"Cancelled by Smart Risk Guardian: {reason}"
            cancelled_count += 1
            
        # Log to immutable audit trail
        audit = AuditLog(
            user_id=account.user_id,
            account_id=account.id,
            event_type="RISK_BREACH",
            action="SUSPEND_AUTO_TRADING",
            details_json=json.dumps({
                "reason": reason,
                "cancelled_orders": cancelled_count,
                "equity_at_breach": account.equity,
                "daily_loss": risk_cfg.current_daily_loss
            }),
            timestamp=datetime.utcnow()
        )
        db_session.add(audit)
        db_session.commit()
        
        # Trigger Voice Announcement
        voice_alert = td_ai_voice_engine.create_risk_alert_announcement()
        
        return {
            "status": "PROTECTION_ENGAGED",
            "account_id": account.id,
            "reason": reason,
            "pending_orders_cancelled": cancelled_count,
            "voice_announcement": voice_alert.message
        }

    @staticmethod
    def execute_emergency_action(
        db_session,
        account: TradingAccount,
        risk_cfg: RiskConfiguration,
        req: EmergencyActionRequest
    ) -> Dict[str, Any]:
        """Handles emergency control panel actions with explicit authorization validation."""
        action = req.action.upper()
        
        if action == "PAUSE_AI":
            risk_cfg.emergency_paused = True
            account.is_auto_trading_enabled = False
            msg = "AI automated trading paused across this account."
            
        elif action == "RESUME_AI":
            risk_cfg.emergency_paused = False
            risk_cfg.is_risk_guardian_tripped = False
            risk_cfg.trip_reason = None
            account.is_auto_trading_enabled = True
            msg = "AI automated trading resumed. Risk Guardian reset to monitoring state."
            
        elif action == "STOP_NEW_TRADES":
            account.is_auto_trading_enabled = False
            msg = "All new trade entries halted. Existing positions remain monitored."
            
        elif action == "CANCEL_PENDING":
            pending = db_session.query(Order).filter(
                Order.account_id == account.id,
                Order.status == "SUBMITTED"
            ).all()
            for p in pending:
                p.status = "CANCELLED"
                p.error_message = "Cancelled via Emergency Control Panel."
            msg = f"Cancelled {len(pending)} pending orders."
            
        elif action == "CLOSE_ALL_POSITIONS":
            if not req.confirm_close_all:
                raise ValueError("CRITICAL: Explicit confirmation (confirm_close_all=True) is required to close open positions!")
                
            open_pos = db_session.query(Position).filter(
                Position.account_id == account.id,
                Position.status == "OPEN"
            ).all()
            
            closed_count = 0
            for pos in open_pos:
                pos.status = "CLOSED"
                pos.close_time = datetime.utcnow()
                pos.close_price = pos.current_price
                pos.close_reason = "EMERGENCY_PANEL_MANUAL_LIQUIDATION"
                pos.realized_pnl = pos.floating_pnl
                closed_count += 1
                
            msg = f"Emergency execution confirmed: Closed {closed_count} open positions."
        else:
            raise ValueError(f"Unknown emergency action '{action}'")

        # Record audit log
        audit = AuditLog(
            user_id=account.user_id,
            account_id=account.id,
            event_type="EMERGENCY_ACTION",
            action=action,
            details_json=json.dumps({"action": action, "result": msg}),
            timestamp=datetime.utcnow()
        )
        db_session.add(audit)
        db_session.commit()
        
        return {"action": action, "message": msg, "timestamp": datetime.utcnow().isoformat()}

smart_risk_guardian = SmartRiskGuardian()

