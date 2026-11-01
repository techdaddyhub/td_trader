"""TD TRADER - Multi-Account Synchronization & Portfolio Exposure Aggregator
Maintains strict account isolation while computing aggregated exposure risk metrics across portfolio.
Never combines funds as if held in a single pool.
"""

from typing import Dict, Any, List
from td_trader.backend.app.models.entities import TradingAccount, Position
from td_trader.backend.app.schemas.schemas import PortfolioSummary
from td_trader.ai_engine.market_scanner.market_data_feed import INSTRUMENT_CATALOG

class AccountSyncAndPortfolioService:
    @staticmethod
    def get_portfolio_summary(db_session, user_id: int) -> PortfolioSummary:
        """Computes aggregate portfolio risk, exposure breakdown, and account isolation reports."""
        accounts = db_session.query(TradingAccount).filter(TradingAccount.user_id == user_id).all()
        
        total_balance = 0.0
        total_equity = 0.0
        total_floating_pnl = 0.0
        total_open_positions = 0
        active_connections = 0
        
        market_exposure: Dict[str, float] = {
            "FOREX": 0.0,
            "CRYPTO": 0.0,
            "METALS": 0.0,
            "INDICES": 0.0,
            "COMMODITIES": 0.0
        }
        
        account_summaries: List[Dict[str, Any]] = []
        
        for acct in accounts:
            total_balance += acct.balance
            total_equity += acct.equity
            total_floating_pnl += acct.floating_pnl
            
            if acct.connection_status == "CONNECTED":
                active_connections += 1
                
            open_pos = db_session.query(Position).filter(
                Position.account_id == acct.id,
                Position.status == "OPEN"
            ).all()
            
            total_open_positions += len(open_pos)
            
            for p in open_pos:
                cat = INSTRUMENT_CATALOG.get(p.instrument, {}).get("category", "FOREX")
                market_exposure[cat] = round(market_exposure.get(cat, 0.0) + p.lots, 2)
                
            account_summaries.append({
                "account_id": acct.id,
                "account_number": acct.account_number,
                "broker_name": acct.broker_name,
                "platform": acct.platform,
                "currency": acct.currency,
                "balance": round(acct.balance, 2),
                "equity": round(acct.equity, 2),
                "free_margin": round(acct.free_margin, 2),
                "used_margin": round(acct.used_margin, 2),
                "floating_pnl": round(acct.floating_pnl, 2),
                "status": acct.connection_status,
                "is_auto_trading_enabled": acct.is_auto_trading_enabled,
                "is_authorized_live": acct.is_authorized_live,
                "open_positions_count": len(open_pos)
            })
            
        return PortfolioSummary(
            total_accounts=len(accounts),
            active_connections=active_connections,
            total_balance=round(total_balance, 2),
            total_equity=round(total_equity, 2),
            total_floating_pnl=round(total_floating_pnl, 2),
            total_open_positions=total_open_positions,
            aggregated_exposure_by_market=market_exposure,
            account_summaries=account_summaries
        )

account_sync_service = AccountSyncAndPortfolioService()

