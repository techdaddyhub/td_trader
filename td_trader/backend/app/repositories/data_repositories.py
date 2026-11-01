"""TD TRADER - Relational Repositories
Clean data access abstractions for Accounts, Orders, Signals, and Audit Logs.
"""

from typing import List, Optional
from td_trader.backend.app.models.entities import TradingAccount, Order, Signal, Position, AuditLog

class AccountRepository:
    def __init__(self, db):
        self.db = db

    def get_by_id(self, account_id: int) -> Optional[TradingAccount]:
        return self.db.query(TradingAccount).filter(TradingAccount.id == account_id).first()

    def get_by_user(self, user_id: int) -> List[TradingAccount]:
        return self.db.query(TradingAccount).filter(TradingAccount.user_id == user_id).all()

    def update_balances(self, account_id: int, balance: float, equity: float, free_margin: float, floating_pnl: float):
        acct = self.get_by_id(account_id)
        if acct:
            acct.balance = balance
            acct.equity = equity
            acct.free_margin = free_margin
            acct.floating_pnl = floating_pnl
            self.db.commit()

class OrderRepository:
    def __init__(self, db):
        self.db = db

    def create(self, order: Order) -> Order:
        self.db.add(order)
        self.db.commit()
        self.db.refresh(order)
        return order

    def get_by_ticket(self, ticket: str) -> Optional[Order]:
        return self.db.query(Order).filter(Order.broker_ticket == ticket).first()

    def get_pending_orders(self, account_id: int) -> List[Order]:
        return self.db.query(Order).filter(Order.account_id == account_id, Order.status == "SUBMITTED").all()

class SignalRepository:
    def __init__(self, db):
        self.db = db

    def create(self, signal: Signal) -> Signal:
        self.db.add(signal)
        self.db.commit()
        self.db.refresh(signal)
        return signal

    def get_active_signals(self, instrument: Optional[str] = None) -> List[Signal]:
        q = self.db.query(Signal).filter(Signal.status == "ACTIVE")
        if instrument:
            q = q.filter(Signal.instrument == instrument)
        return q.all()

