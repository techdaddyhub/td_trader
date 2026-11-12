"""TD TRADER - MetaTrader 4 & 5 Real Bi-Directional HTTP/WebRequest Bridge Connector
Copyright (c) 2026 TechDaddy. All rights reserved.

Maintains live telemetry sessions with attached MT4 & MT5 Expert Advisors via WebRequest,
queues validated orders/close commands, and awaits real broker ticket confirmation receipts.
"""

from typing import Dict, Any, List, Optional
import asyncio
import uuid
from datetime import datetime, timedelta
from td_trader.backend.app.core.security import decrypt_broker_credential
from td_trader.backend.app.models.entities import TradingAccount


class MetaTraderBridgeConnector:
    """Manages active real-time communication with MetaTrader 4 & 5 terminals."""

    def __init__(self):
        self.connected_terminals: Dict[str, Dict[str, Any]] = {}
        self.pending_commands: Dict[str, List[Dict[str, Any]]] = {}
        self.pending_confirmations: Dict[str, asyncio.Future] = {}

    def authenticate_terminal(self, account: TradingAccount) -> bool:
        """Verifies credential decryption in-memory for terminal registration."""
        if not account.encrypted_credentials:
            return False
        try:
            _ = decrypt_broker_credential(account.encrypted_credentials)
            return True
        except Exception:
            return False

    def is_terminal_online(self, account_number: str, ttl_seconds: int = 20) -> bool:
        """Returns True if an MT4/MT5 EA for this account checked in within ttl_seconds."""
        key = str(account_number).strip()
        info = self.connected_terminals.get(key)
        if not info:
            return False
        last_dt = info.get("last_sync_dt")
        if not isinstance(last_dt, datetime):
            return False
        return (datetime.utcnow() - last_dt) <= timedelta(seconds=ttl_seconds)

    def get_bridge_status(self, ttl_seconds: int = 20) -> Dict[str, Any]:
        """Return live status summary of all connected MT4/MT5 EA terminals."""
        now = datetime.utcnow()
        terminals = []
        for acct_num, info in self.connected_terminals.items():
            last_dt = info.get("last_sync_dt")
            age = int((now - last_dt).total_seconds()) if isinstance(last_dt, datetime) else 9999
            online = age <= ttl_seconds
            terminals.append({
                "account_number": acct_num,
                "platform": info.get("platform", "MT5"),
                "broker": info.get("broker", ""),
                "server": info.get("server", ""),
                "balance": info.get("balance", 0.0),
                "equity": info.get("equity", 0.0),
                "free_margin": info.get("free_margin", 0.0),
                "floating_pnl": info.get("floating_pnl", 0.0),
                "open_positions": info.get("open_positions", 0),
                "status": "ONLINE" if online else "STALE",
                "seconds_since_heartbeat": age,
                "last_sync": info.get("last_sync"),
            })
        return {
            "online_count": sum(1 for t in terminals if t["status"] == "ONLINE"),
            "terminals": terminals,
        }

    def record_heartbeat(self, db_session, telemetry: Dict[str, Any]) -> List[Dict[str, Any]]:
        """Process live heartbeat from MT4/MT5 EA, sync DB account metrics, return queued commands."""
        acct_num = str(telemetry.get("account", telemetry.get("login", telemetry.get("account_number", "")))).strip()
        if not acct_num:
            return []

        now = datetime.utcnow()
        self.connected_terminals[acct_num] = {
            "account_number": acct_num,
            "platform": telemetry.get("platform", "MT5"),
            "broker": telemetry.get("broker", ""),
            "server": telemetry.get("server", ""),
            "balance": float(telemetry.get("balance", 0.0)),
            "equity": float(telemetry.get("equity", 0.0)),
            "free_margin": float(telemetry.get("free_margin", 0.0)),
            "used_margin": float(telemetry.get("margin", telemetry.get("used_margin", 0.0))),
            "floating_pnl": float(telemetry.get("floating_pnl", telemetry.get("profit", 0.0))),
            "open_positions": int(telemetry.get("positions", telemetry.get("open_trades", 0))),
            "last_sync_dt": now,
            "last_sync": now.isoformat(),
            "status": "ONLINE",
        }

        # Sync live broker metrics to matching TradingAccount record(s)
        matching_accounts = db_session.query(TradingAccount).filter(
            TradingAccount.account_number == acct_num
        ).all()
        for acct in matching_accounts:
            acct.balance = self.connected_terminals[acct_num]["balance"]
            acct.equity = self.connected_terminals[acct_num]["equity"]
            acct.free_margin = self.connected_terminals[acct_num]["free_margin"]
            acct.used_margin = self.connected_terminals[acct_num]["used_margin"]
            acct.floating_pnl = self.connected_terminals[acct_num]["floating_pnl"]
            acct.connection_status = "CONNECTED"
        if matching_accounts:
            db_session.commit()

        commands = self.pending_commands.pop(acct_num, [])
        return commands

    def record_order_confirmation(self, confirmation: Dict[str, Any]) -> bool:
        """Resolve an awaiting execution future when the MT4/MT5 EA reports fill/rejection."""
        client_oid = str(confirmation.get("client_order_id", "")).strip()
        future = self.pending_confirmations.get(client_oid)
        if future and not future.done():
            future.set_result(confirmation)
            return True
        return False

    async def _enqueue_and_wait(
        self,
        account_number: str,
        command: Dict[str, Any],
        timeout: float = 12.0,
    ) -> Dict[str, Any]:
        acct_key = str(account_number).strip()
        client_oid = str(command["client_order_id"])
        loop = asyncio.get_running_loop()
        future: asyncio.Future = loop.create_future()
        self.pending_confirmations[client_oid] = future

        self.pending_commands.setdefault(acct_key, []).append(command)
        try:
            result = await asyncio.wait_for(future, timeout=timeout)
            return result
        except asyncio.TimeoutError:
            # Remove unconsumed command if EA timed out
            queued = self.pending_commands.get(acct_key, [])
            self.pending_commands[acct_key] = [
                c for c in queued if c.get("client_order_id") != client_oid
            ]
            return {
                "confirmed": False,
                "status": "BRIDGE_TIMEOUT",
                "error": (
                    f"MetaTrader terminal #{acct_key} did not confirm execution within {int(timeout)}s. "
                    "Verify AutoTrading is enabled and TDTrader_Bridge EA is running on a chart."
                ),
            }
        finally:
            self.pending_confirmations.pop(client_oid, None)

    async def dispatch_order_to_terminal_async(
        self,
        account: TradingAccount,
        order_payload: Dict[str, Any],
        timeout: float = 12.0,
    ) -> Dict[str, Any]:
        """Dispatch validated order to live MT4/MT5 EA bridge and await broker confirmation ticket."""
        if "LIVE" in account.platform and not account.is_authorized_live:
            return {
                "confirmed": False,
                "status": "REJECTED_UNAUTHORIZED",
                "error": "Live automated trading requires explicit user authorization.",
            }

        acct_num = str(account.account_number).strip()
        if not self.is_terminal_online(acct_num):
            return {
                "confirmed": False,
                "status": "BRIDGE_OFFLINE",
                "error": (
                    f"MetaTrader EA bridge is offline for account #{acct_num}. "
                    "Attach TDTrader_Bridge_MT5/MT4 onto any chart and enable Allow WebRequest for your TD Trader URL."
                ),
            }

        command = {
            "action": "OPEN_ORDER",
            "client_order_id": order_payload["client_order_id"],
            "instrument": order_payload["instrument"],
            "direction": order_payload["direction"],
            "lots": float(order_payload["lots"]),
            "stop_loss": float(order_payload.get("stop_loss") or 0.0),
            "take_profit": float(order_payload.get("take_profit") or 0.0),
        }
        receipt = await self._enqueue_and_wait(acct_num, command, timeout=timeout)
        if not receipt.get("confirmed", False):
            return {
                "confirmed": False,
                "status": receipt.get("status", "BROKER_REJECTED"),
                "error": receipt.get("error", "Broker terminal rejected order."),
            }

        return {
            "confirmed": True,
            "status": "CONFIRMED",
            "broker_ticket": str(receipt.get("broker_ticket", "")),
            "fill_price": float(receipt.get("fill_price", order_payload.get("requested_price", 0.0))),
            "slippage_pips": float(receipt.get("slippage_pips", 0.0)),
            "confirmed_at": datetime.utcnow().isoformat(),
            "lots_filled": float(receipt.get("lots_filled", order_payload.get("lots", 0.01))),
        }

    async def close_terminal_position_async(
        self,
        account: TradingAccount,
        position_ticket: str,
        timeout: float = 12.0,
    ) -> Dict[str, Any]:
        """Dispatch position close command to connected MT4/MT5 EA terminal."""
        acct_num = str(account.account_number).strip()
        if not self.is_terminal_online(acct_num):
            return {
                "confirmed": False,
                "status": "BRIDGE_OFFLINE",
                "error": f"MetaTrader EA bridge is offline for account #{acct_num}.",
            }
        command = {
            "action": "CLOSE_POSITION",
            "client_order_id": f"close_{uuid.uuid4().hex[:10]}",
            "broker_ticket": str(position_ticket),
        }
        return await self._enqueue_and_wait(acct_num, command, timeout=timeout)


bridge_connector = MetaTraderBridgeConnector()
