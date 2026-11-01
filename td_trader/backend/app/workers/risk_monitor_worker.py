"""TD TRADER - Asynchronous Risk Guardian Monitor Worker
Continuously inspects account metrics, daily drawdowns, consecutive losses,
and engages automatic protection protocols upon threshold breach.
"""

import asyncio
from datetime import datetime
from td_trader.backend.app.models.entities import SessionLocal, TradingAccount, RiskConfiguration
from td_trader.ai_engine.risk_engine.risk_guardian import smart_risk_guardian
from td_trader.backend.app.websocket.connection_manager import ws_manager

class RiskGuardianMonitorWorker:
    def __init__(self, interval_seconds: int = 5):
        self.interval = interval_seconds
        self._running = False

    async def start(self):
        self._running = True
        print(f"[WORKER] Smart Risk Guardian monitor worker started (interval: {self.interval}s)")
        while self._running:
            try:
                db = SessionLocal()
                try:
                    accounts = db.query(TradingAccount).filter(TradingAccount.is_auto_trading_enabled == True).all()
                    for acct in accounts:
                        risk_cfg = db.query(RiskConfiguration).filter(RiskConfiguration.account_id == acct.id).first()
                        if not risk_cfg or risk_cfg.is_risk_guardian_tripped:
                            continue
                            
                        # Evaluate Daily Loss threshold
                        if risk_cfg.current_daily_loss >= risk_cfg.max_daily_loss_amount:
                            reason = f"Max daily loss threshold (${risk_cfg.max_daily_loss_amount:.2f}) reached."
                            res = smart_risk_guardian.trigger_protection_protocol(db, acct, risk_cfg, reason)
                            await ws_manager.broadcast_event("RISK_LIMIT_REACHED", res)
                            print(f"[RISK GUARDIAN] Tripped for account #{acct.account_number}: {reason}")
                            
                        # Evaluate Consecutive Losses threshold
                        elif risk_cfg.current_consecutive_losses >= risk_cfg.consecutive_loss_limit:
                            reason = f"Consecutive loss lockout ({risk_cfg.consecutive_loss_limit} trades) reached."
                            res = smart_risk_guardian.trigger_protection_protocol(db, acct, risk_cfg, reason)
                            await ws_manager.broadcast_event("RISK_LIMIT_REACHED", res)
                            print(f"[RISK GUARDIAN] Tripped for account #{acct.account_number}: {reason}")
                finally:
                    db.close()
            except Exception as e:
                print(f"[WORKER ERROR] Risk monitor cycle error: {e}")
            await asyncio.sleep(self.interval)

    def stop(self):
        self._running = False

risk_monitor_worker = RiskGuardianMonitorWorker(5)

