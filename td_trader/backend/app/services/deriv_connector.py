"""TD TRADER - Deriv Broker Native WebSocket API v3 Connector
Copyright (c) 2026 TechDaddy. All rights reserved.

Integrates directly with Deriv (wss://ws.derivws.com/websockets/v3) for:
  - Demo (VRTC) and Real/Live (CR) account token verification & authorization
  - Live tick quotes and historical OHLCV candle streaming (Volatility, Boom/Crash, Step, Jump, Forex)
  - Multiplier / contract order proposal, confirmed buy execution, portfolio sync, and closing
  - Unified symbol mapping between TD Trader catalog tickers and Deriv API symbols
"""

from typing import Dict, Any, Optional, List, Tuple
from datetime import datetime
import json
import re
import pandas as pd
import websockets

from td_trader.backend.app.core.security import decrypt_broker_credential
from td_trader.backend.app.models.entities import TradingAccount
from td_trader.ai_engine.market_scanner.market_data_feed import INSTRUMENT_CATALOG, market_data_feed

DERIV_WS_BASE_URL = "wss://ws.derivws.com/websockets/v3"
DEFAULT_DERIV_APP_ID = "1089"

TIMEFRAME_GRANULARITY_SECONDS: Dict[str, int] = {
    "M1": 60,
    "M5": 300,
    "M15": 900,
    "M30": 1800,
    "H1": 3600,
    "H4": 14400,
    "D1": 86400,
}

# Pre-build TD symbol <-> Deriv API symbol mappings from INSTRUMENT_CATALOG
DERIV_SYMBOL_MAP: Dict[str, str] = {
    sym: meta["deriv_symbol"]
    for sym, meta in INSTRUMENT_CATALOG.items()
    if "deriv_symbol" in meta
}
REVERSE_DERIV_SYMBOL_MAP: Dict[str, str] = {
    deriv_sym: td_sym for td_sym, deriv_sym in DERIV_SYMBOL_MAP.items()
}


class DerivConnector:
    """Bi-directional WebSocket connector for Deriv Native API (Demo VRTC & Live CR)."""

    @staticmethod
    def build_ws_url(app_id: str = DEFAULT_DERIV_APP_ID) -> str:
        clean_id = re.sub(r"[^0-9]", "", str(app_id or "")) or DEFAULT_DERIV_APP_ID
        return f"{DERIV_WS_BASE_URL}?app_id={clean_id}"

    @staticmethod
    def to_deriv_symbol(symbol: str) -> str:
        upper = symbol.strip().upper()
        if upper in DERIV_SYMBOL_MAP:
            return DERIV_SYMBOL_MAP[upper]
        return symbol.strip()

    @staticmethod
    def to_td_symbol(deriv_symbol: str) -> str:
        if deriv_symbol in REVERSE_DERIV_SYMBOL_MAP:
            return REVERSE_DERIV_SYMBOL_MAP[deriv_symbol]
        return deriv_symbol

    @staticmethod
    def unpack_credentials(account: TradingAccount) -> Tuple[str, str]:
        """Decrypt and extract (api_token, app_id) strictly in-memory."""
        if not account.encrypted_credentials:
            return "", DEFAULT_DERIV_APP_ID
        decrypted = decrypt_broker_credential(account.encrypted_credentials)
        app_id = DEFAULT_DERIV_APP_ID

        # Extract App ID hint from server string if stored like "ws.derivws.com (AppID: 12345)"
        if account.server:
            m = re.search(r"AppID:\s*(\d+)", account.server, re.IGNORECASE)
            if m:
                app_id = m.group(1)

        try:
            parsed = json.loads(decrypted)
            if isinstance(parsed, dict):
                return str(parsed.get("api_token", "")).strip(), str(
                    parsed.get("app_id", app_id)
                ).strip() or DEFAULT_DERIV_APP_ID
        except (ValueError, TypeError):
            pass

        return decrypted.strip(), app_id

    @staticmethod
    def get_supported_instruments() -> List[Dict[str, Any]]:
        """Return list of catalog instruments mapped to Deriv WebSocket symbols."""
        items = []
        for sym, meta in INSTRUMENT_CATALOG.items():
            if "deriv_symbol" in meta:
                items.append({
                    "td_symbol": sym,
                    "deriv_symbol": meta["deriv_symbol"],
                    "display_name": meta.get("display_name", sym),
                    "category": meta["category"],
                    "digits": meta["digits"],
                    "pip_size": meta["pip_size"],
                })
        return items

    async def _send_ws_sequence(
        self,
        payloads: List[Dict[str, Any]],
        app_id: str = DEFAULT_DERIV_APP_ID,
        timeout: float = 12.0,
    ) -> List[Dict[str, Any]]:
        """Execute a sequential list of Deriv WebSocket RPC messages on one session."""
        url = self.build_ws_url(app_id)
        responses: List[Dict[str, Any]] = []
        async with websockets.connect(url, open_timeout=timeout, close_timeout=5) as ws:
            for payload in payloads:
                await ws.send(json.dumps(payload))
                raw = await ws.recv()
                msg = json.loads(raw)
                if "error" in msg:
                    err = msg["error"]
                    raise RuntimeError(
                        f"Deriv API Error ({err.get('code', 'UNKNOWN')}): {err.get('message', 'Request rejected')}"
                    )
                responses.append(msg)
        return responses

    async def authorize_token(
        self,
        api_token: str,
        app_id: str = DEFAULT_DERIV_APP_ID,
    ) -> Dict[str, Any]:
        """Verify Deriv API Token via live WebSocket handshake and return verified account profile."""
        token = api_token.strip()
        if not token:
            raise ValueError("Deriv API token cannot be empty.")

        responses = await self._send_ws_sequence([{"authorize": token}], app_id=app_id)
        auth = responses[0].get("authorize", {})
        is_virtual = bool(auth.get("is_virtual", 1))
        loginid = auth.get("loginid", "")
        sub_accounts = [
            {
                "loginid": a.get("loginid"),
                "currency": a.get("currency"),
                "is_virtual": bool(a.get("is_virtual", 0)),
                "account_category": a.get("account_category"),
                "platform": a.get("platform"),
            }
            for a in auth.get("account_list", [])
        ]

        return {
            "verified": True,
            "loginid": loginid,
            "is_virtual": is_virtual,
            "recommended_platform": "DERIV_API_DEMO" if is_virtual else "DERIV_API_LIVE",
            "balance": float(auth.get("balance", 0.0)),
            "currency": auth.get("currency", "USD"),
            "email": auth.get("email", ""),
            "fullname": auth.get("fullname", ""),
            "app_id": re.sub(r"[^0-9]", "", str(app_id or "")) or DEFAULT_DERIV_APP_ID,
            "server": f"ws.derivws.com (AppID: {app_id or DEFAULT_DERIV_APP_ID})",
            "sub_accounts": sub_accounts,
        }

    async def fetch_live_tick(
        self,
        symbol: str,
        app_id: str = DEFAULT_DERIV_APP_ID,
    ) -> Dict[str, Any]:
        """Fetch latest live Deriv tick snapshot and update MarketDataFeed."""
        deriv_sym = self.to_deriv_symbol(symbol)
        responses = await self._send_ws_sequence([{"ticks": deriv_sym}], app_id=app_id)
        tick = responses[0].get("tick", {})
        quote_price = float(tick.get("quote", 0.0))

        meta = INSTRUMENT_CATALOG.get(symbol, {"pip_size": 0.01, "typical_spread": 2.0, "digits": 2})
        half_spread = (meta["typical_spread"] * meta["pip_size"]) / 2.0
        bid = float(tick.get("bid") or (quote_price - half_spread))
        ask = float(tick.get("ask") or (quote_price + half_spread))

        if symbol in INSTRUMENT_CATALOG:
            market_data_feed.update_tick(
                symbol=symbol,
                bid=bid,
                ask=ask,
                is_real_time=True,
                delay_seconds=0,
                source="DERIV_WS",
            )

        return {
            "symbol": symbol,
            "deriv_symbol": deriv_sym,
            "bid": round(bid, meta["digits"]),
            "ask": round(ask, meta["digits"]),
            "quote": quote_price,
            "epoch": tick.get("epoch"),
            "source": "DERIV_WS",
        }

    async def fetch_candles(
        self,
        symbol: str,
        timeframe: str = "H1",
        count: int = 150,
        app_id: str = DEFAULT_DERIV_APP_ID,
    ) -> pd.DataFrame:
        """Fetch historical OHLCV candles from Deriv and update MarketDataFeed cache."""
        deriv_sym = self.to_deriv_symbol(symbol)
        granularity = TIMEFRAME_GRANULARITY_SECONDS.get(timeframe.upper(), 3600)
        req = {
            "ticks_history": deriv_sym,
            "adjust_start_time": 1,
            "count": min(max(int(count), 10), 1000),
            "end": "latest",
            "granularity": granularity,
            "style": "candles",
        }
        responses = await self._send_ws_sequence([req], app_id=app_id)
        raw_candles = responses[0].get("candles", [])
        if not raw_candles:
            raise RuntimeError(f"No candle history returned by Deriv for {deriv_sym}")

        rows = []
        for c in raw_candles:
            rows.append({
                "timestamp": pd.to_datetime(int(c["epoch"]), unit="s"),
                "open": float(c["open"]),
                "high": float(c["high"]),
                "low": float(c["low"]),
                "close": float(c["close"]),
                "volume": 1000,
            })
        df = pd.DataFrame(rows).set_index("timestamp")
        if symbol in INSTRUMENT_CATALOG:
            market_data_feed.update_candles(symbol, timeframe.upper(), df)
        return df

    async def dispatch_deriv_order_async(
        self,
        account: TradingAccount,
        order_payload: Dict[str, Any],
    ) -> Dict[str, Any]:
        """Authorize, request Deriv Multiplier proposal, and execute confirmed buy contract."""
        # Strict Live Capital Protection
        if "LIVE" in account.platform and not account.is_authorized_live:
            return {
                "confirmed": False,
                "status": "REJECTED_UNAUTHORIZED",
                "error": "Live Deriv automated trading requires explicit user authorization.",
            }

        api_token, app_id = self.unpack_credentials(account)
        if not api_token:
            return {
                "confirmed": False,
                "status": "MISSING_CREDENTIALS",
                "error": "No encrypted Deriv API token found on this account.",
            }

        symbol = order_payload["instrument"]
        deriv_sym = self.to_deriv_symbol(symbol)
        direction = order_payload["direction"].upper()
        contract_type = "MULTUP" if direction == "BUY" else "MULTDOWN"
        lots = float(order_payload.get("lots", 0.1))
        stake = max(1.0, round(lots * 100.0, 2))
        entry_price = float(order_payload.get("requested_price", 1.0))
        sl_price = order_payload.get("stop_loss")
        tp_price = order_payload.get("take_profit")

        # Derive Multiplier risk thresholds in account currency from SL/TP distance ratio
        limit_order: Dict[str, float] = {}
        if sl_price and entry_price > 0:
            sl_pct = abs(entry_price - float(sl_price)) / entry_price
            sl_usd = round(max(0.5, min(stake, stake * sl_pct * 100.0)), 2)
            limit_order["stop_loss"] = sl_usd
        if tp_price and entry_price > 0:
            tp_pct = abs(float(tp_price) - entry_price) / entry_price
            tp_usd = round(max(0.5, stake * tp_pct * 100.0), 2)
            limit_order["take_profit"] = tp_usd

        proposal_req: Dict[str, Any] = {
            "proposal": 1,
            "amount": stake,
            "basis": "stake",
            "contract_type": contract_type,
            "currency": account.currency or "USD",
            "multiplier": 100,
            "symbol": deriv_sym,
        }
        if limit_order:
            proposal_req["limit_order"] = limit_order

        url = self.build_ws_url(app_id)
        try:
            async with websockets.connect(url, open_timeout=12.0, close_timeout=5) as ws:
                # 1. Authorize token
                await ws.send(json.dumps({"authorize": api_token}))
                auth_msg = json.loads(await ws.recv())
                if "error" in auth_msg:
                    err = auth_msg["error"]
                    return {
                        "confirmed": False,
                        "status": "AUTH_FAILED",
                        "error": f"{err.get('code', 'AUTH')}: {err.get('message', 'Unauthorized token')}",
                    }

                # 2. Request live executable quote proposal
                await ws.send(json.dumps(proposal_req))
                prop_msg = json.loads(await ws.recv())
                if "error" in prop_msg:
                    err = prop_msg["error"]
                    return {
                        "confirmed": False,
                        "status": "PROPOSAL_REJECTED",
                        "error": f"{err.get('code', 'PROPOSAL')}: {err.get('message', 'Proposal rejected by Deriv')}",
                    }

                proposal = prop_msg.get("proposal", {})
                prop_id = proposal.get("id")
                ask_price = float(proposal.get("ask_price", stake))
                spot_price = float(proposal.get("spot", entry_price))

                # 3. Execute Buy Contract
                await ws.send(json.dumps({"buy": prop_id, "price": ask_price}))
                buy_msg = json.loads(await ws.recv())
                if "error" in buy_msg:
                    err = buy_msg["error"]
                    return {
                        "confirmed": False,
                        "status": "EXECUTION_REJECTED",
                        "error": f"{err.get('code', 'BUY')}: {err.get('message', 'Buy rejected by Deriv')}",
                    }

                buy_data = buy_msg.get("buy", {})
                contract_id = str(buy_data.get("contract_id", ""))
                ticket = f"DERIV_{contract_id}"

                return {
                    "confirmed": True,
                    "status": "CONFIRMED",
                    "broker_ticket": ticket,
                    "deriv_contract_id": contract_id,
                    "deriv_transaction_id": str(buy_data.get("transaction_id", "")),
                    "fill_price": spot_price,
                    "slippage_pips": 0.0,
                    "balance_after": buy_data.get("balance_after"),
                    "confirmed_at": datetime.utcnow().isoformat(),
                    "lots_filled": lots,
                }
        except Exception as exc:
            return {
                "confirmed": False,
                "status": "CONNECTION_ERROR",
                "error": f"Deriv WebSocket execution failed: {exc}",
            }

    async def close_contract_async(
        self,
        account: TradingAccount,
        position_ticket: str,
    ) -> Dict[str, Any]:
        """Close an active Deriv contract at market price via WebSocket sell endpoint."""
        api_token, app_id = self.unpack_credentials(account)
        if not api_token:
            raise ValueError("Missing encrypted Deriv API token on account.")

        contract_id = position_ticket.replace("DERIV_", "").strip()
        if not contract_id.isdigit():
            raise ValueError(f"Invalid Deriv contract ticket format: {position_ticket}")

        responses = await self._send_ws_sequence(
            [
                {"authorize": api_token},
                {"sell": int(contract_id), "price": 0},
            ],
            app_id=app_id,
        )
        sell_data = responses[1].get("sell", {})
        return {
            "confirmed": True,
            "contract_id": contract_id,
            "sold_for": float(sell_data.get("sold_for", 0.0)),
            "transaction_id": sell_data.get("transaction_id"),
        }


deriv_connector = DerivConnector()
