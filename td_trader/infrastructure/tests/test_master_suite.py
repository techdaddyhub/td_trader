"""TD TRADER - Master Quantitative & Fintech Test Suite
Verifies all 5 mandatory core modules, 16 risk gates, backtest execution, and API contracts.
"""

import unittest
import sys
import os
import json
import numpy as np
import pandas as pd

# Add repository root to python path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "../../../")))

from td_trader.backend.app.core.security import (
    hash_password, verify_password, encrypt_broker_credential, decrypt_broker_credential,
    create_access_token, verify_access_token
)
from td_trader.ai_engine.technical_analysis.indicators import TechnicalIndicators
from td_trader.ai_engine.technical_analysis.market_structure import MarketStructureAnalyzer
from td_trader.ai_engine.opportunity_ranker.ranker import OpportunityRanker
from td_trader.ai_engine.market_scanner.scanner import ai_market_scanner
from td_trader.ai_engine.voice_engine.voice_service import td_ai_voice_engine, AudioWaveSynthesizer
from td_trader.ai_engine.risk_engine.risk_guardian import smart_risk_guardian
from td_trader.backtesting.simulation.engine import backtest_engine
from td_trader.backend.app.schemas.schemas import BacktestRequest, VoiceQueryRequest, EmergencyActionRequest
from td_trader.backend.app.models.entities import init_db, SessionLocal, User, TradingAccount, RiskConfiguration
from starlette.testclient import TestClient
from td_trader.backend.app.main import app

class MasterTDTraderTestSuite(unittest.TestCase):
    
    @classmethod
    def setUpClass(cls):
        init_db()
        cls.client = TestClient(app)

    # --- TEST SECURITY & CRYPTOGRAPHY ---
    def test_01_security_cryptography(self):
        pwd = "EnterpriseFintechPassword#2026!"
        h = hash_password(pwd)
        self.assertTrue(verify_password(pwd, h))
        self.assertFalse(verify_password("WrongPassword!", h))

        # Test AES-256 Fernet broker password encryption
        secret_meta_pass = "MySecretBrokerPass999$"
        enc = encrypt_broker_credential(secret_meta_pass)
        self.assertNotEqual(secret_meta_pass, enc)
        self.assertEqual(secret_meta_pass, decrypt_broker_credential(enc))

        # Test JWT token signing & verification
        token = create_access_token({"user_id": 42, "role": "senior_trader"})
        payload = verify_access_token(token)
        self.assertIsNotNone(payload)
        self.assertEqual(payload["user_id"], 42)

    # --- MODULE 1: AI MULTI-MARKET SCANNER TESTS ---
    def test_02_ai_multi_market_scanner(self):
        opps = ai_market_scanner.scan_all_markets()
        self.assertGreater(len(opps), 0, "Scanner must detect active multi-market opportunities")
        
        top = opps[0]
        self.assertGreaterEqual(top.score, 0.0)
        self.assertLessEqual(top.score, 100.0)
        
        # Verify Opportunity Ranking formula components
        bd = top.score_breakdown
        self.assertLessEqual(bd.trend_alignment, 20.0)
        self.assertLessEqual(bd.technical_confirmation, 20.0)
        self.assertLessEqual(bd.momentum, 15.0)
        self.assertLessEqual(bd.market_structure, 15.0)
        self.assertLessEqual(bd.volatility, 10.0)
        self.assertLessEqual(bd.risk_reward, 10.0)
        self.assertLessEqual(bd.strategy_validation, 10.0)
        
        # Verify market categories supported
        categories = {o.market_category for o in opps}
        self.assertTrue(any(c in categories for c in ["FOREX", "CRYPTO", "METALS", "INDICES", "COMMODITIES"]))

    # --- MODULE 2: TD AI VOICE ASSISTANT TESTS ---
    def test_03_td_ai_voice_engine(self):
        # 1. Test mandatory voice announcement scripts
        sig_ann = td_ai_voice_engine.create_new_signal_announcement("XAUUSD", "BUY", "bullish")
        self.assertIn("TD Trader alert", sig_ann.message)
        self.assertIn("XAUUSD", sig_ann.message)
        self.assertIsNotNone(sig_ann.audio_base64)

        exec_ann = td_ai_voice_engine.create_trade_execution_announcement("EURUSD", "buy")
        self.assertIn("Your EURUSD buy order has been confirmed by your broker", exec_ann.message)

        close_ann = td_ai_voice_engine.create_trade_closure_announcement()
        self.assertIn("Your position has been closed", close_ann.message)

        risk_ann = td_ai_voice_engine.create_risk_alert_announcement()
        self.assertIn("Risk Guardian activated", risk_ann.message)

        # 2. Test conversational fact vs AI interpretation separation
        req = VoiceQueryRequest(query="Analyse gold for me", voice_personality="Aria_Fintech_Pro")
        res = td_ai_voice_engine.process_conversation(req)
        self.assertIn("verified_facts", res.model_dump())
        self.assertIn("ai_interpretation", res.model_dump())
        self.assertIn("XAUUSD", res.verified_facts.get("symbol", ""))

        # 3. Test SSML markup generation
        ssml = td_ai_voice_engine.build_ssml("Market volatility alert.", "Aria_Fintech_Pro")
        self.assertTrue(ssml.startswith("<speak"))

    # --- MODULE 3: SMART RISK GUARDIAN TESTS ---
    def test_04_smart_risk_guardian(self):
        db = SessionLocal()
        try:
            # 1. Test mathematical position sizing formula
            lots = smart_risk_guardian.calculate_lot_size(
                equity=10000.0,
                risk_pct=1.0,           # $100 risk
                entry_price=1.0850,
                stop_loss=1.0830,       # 20 pips distance
                symbol="EURUSD",
                max_lot_size=5.0
            )
            self.assertEqual(lots, 0.50, "10000 * 1% ($100) / (20 pips * $10/pip) should equal 0.50 lots")

            # 2. Test Emergency Control Panel actions
            acct = db.query(TradingAccount).first()
            if not acct:
                acct = TradingAccount(
                    user_id=1, account_number="TEST_ACCT_01", broker_name="TestBroker",
                    server="TestServer", platform="PAPER_TRADING", balance=10000.0, equity=10000.0
                )
                db.add(acct)
                db.commit()

            cfg = db.query(RiskConfiguration).filter(RiskConfiguration.account_id == acct.id).first()
            if not cfg:
                cfg = RiskConfiguration(account_id=acct.id, daily_starting_equity=10000.0)
                db.add(cfg)
                db.commit()

            # Execute PAUSE_AI
            res_pause = smart_risk_guardian.execute_emergency_action(db, acct, cfg, EmergencyActionRequest(action="PAUSE_AI"))
            self.assertTrue(cfg.emergency_paused)
            self.assertFalse(acct.is_auto_trading_enabled)

            # Test explicit confirmation requirement for CLOSE_ALL_POSITIONS
            with self.assertRaises(ValueError):
                smart_risk_guardian.execute_emergency_action(
                    db, acct, cfg, EmergencyActionRequest(action="CLOSE_ALL_POSITIONS", confirm_close_all=False)
                )

            # Resume AI
            smart_risk_guardian.execute_emergency_action(db, acct, cfg, EmergencyActionRequest(action="RESUME_AI"))
            self.assertFalse(cfg.emergency_paused)
        finally:
            db.close()

    # --- MODULE 4: AI STRATEGY BACKTESTER TESTS ---
    def test_05_ai_strategy_backtester(self):
        req = BacktestRequest(
            strategy_name="MA_Crossover",
            instrument="EURUSD",
            timeframe="H1",
            start_date="2026-01-01",
            end_date="2026-11-01",
            initial_balance=10000.0,
            risk_per_trade_pct=1.0,
            spread_pips=1.2,
            commission_per_lot=5.0,
            slippage_pips=0.5,
            run_walk_forward=True
        )
        res = backtest_engine.run_backtest(req)
        self.assertGreater(res.total_trades, 0)
        self.assertIsNotNone(res.win_rate)
        self.assertIsNotNone(res.profit_factor)
        self.assertIsNotNone(res.max_drawdown_pct)
        self.assertIsNotNone(res.walk_forward_metrics)
        self.assertIn("walk_forward_efficiency_pct", res.walk_forward_metrics)
        self.assertIn("overfitting_risk_score", res.walk_forward_metrics)

        # Test side-by-side strategy comparison
        comparisons = backtest_engine.compare_strategies("XAUUSD", ["MA_Crossover", "RSI_Dynamic_Reversal", "MACD_Momentum"])
        self.assertEqual(len(comparisons), 3)

    # --- MODULE 5: MULTI-ACCOUNT MANAGER TESTS ---
    def test_06_multi_account_manager(self):
        res = self.client.get("/api/v1/accounts/")
        self.assertEqual(res.status_code, 200)
        accounts = res.json()
        self.assertIsInstance(accounts, list)

        # Verify portfolio summary endpoint (with strict isolation guarantee)
        sum_res = self.client.get("/api/v1/accounts/portfolio/summary")
        self.assertEqual(sum_res.status_code, 200)
        summary = sum_res.json()
        self.assertIn("aggregated_exposure_by_market", summary)
        self.assertIn("SYNTHETICS", summary["aggregated_exposure_by_market"])
        self.assertIn("account_summaries", summary)

    # --- MODULE 6: DERIV BROKER & SYNTHETICS INTEGRATION TESTS ---
    def test_07_deriv_broker_integration(self):
        import asyncio
        import time
        import uuid
        from unittest.mock import patch
        from td_trader.backend.app.services.deriv_connector import deriv_connector
        from td_trader.ai_engine.market_scanner.market_data_feed import INSTRUMENT_CATALOG
        from td_trader.backend.app.models.entities import Position

        # 1. Verify Deriv Synthetic Indices catalog & symbol mappings
        for sym, expected_deriv in [("V75", "R_75"), ("V75_1S", "1HZ75V"), ("BOOM1000", "BOOM1000"), ("STEP", "stpRNG")]:
            self.assertIn(sym, INSTRUMENT_CATALOG)
            self.assertEqual(INSTRUMENT_CATALOG[sym]["category"], "SYNTHETICS")
            self.assertEqual(deriv_connector.to_deriv_symbol(sym), expected_deriv)
            self.assertEqual(deriv_connector.to_td_symbol(expected_deriv), sym)

        # 2. Verify Deriv instruments REST endpoint
        inst_res = self.client.get("/api/v1/brokers/deriv/instruments")
        self.assertEqual(inst_res.status_code, 200)
        inst_list = inst_res.json()
        self.assertTrue(any(item["td_symbol"] == "V75" and item["deriv_symbol"] == "R_75" for item in inst_list))

        # 3. Verify encrypted credential packing/unpacking & account creation for Deriv API Demo & Live
        cred_json = json.dumps({"api_token": "deriv_test_token_xyz", "app_id": "54321"})
        create_res = self.client.post("/api/v1/accounts/", json={
            "account_number": "VRTC999888",
            "broker_name": "Deriv Native WS API",
            "server": "ws.derivws.com (AppID: 54321)",
            "platform": "DERIV_API_DEMO",
            "currency": "USD",
            "password": cred_json,
            "balance": 10000.0,
            "is_auto_trading_enabled": True,
            "is_authorized_live": False,
        })
        self.assertEqual(create_res.status_code, 200)
        acct_id = create_res.json()["id"]

        db = SessionLocal()
        try:
            acct = db.query(TradingAccount).filter(TradingAccount.id == acct_id).first()
            self.assertIsNotNone(acct)
            token, app_id = deriv_connector.unpack_credentials(acct)
            self.assertEqual(token, "deriv_test_token_xyz")
            self.assertEqual(app_id, "54321")

            # Live Deriv account without explicit authorization must be rejected
            live_acct = TradingAccount(
                user_id=1, account_number="CR777666", broker_name="Deriv Native WS API",
                server="ws.derivws.com", platform="DERIV_API_LIVE",
                encrypted_credentials=acct.encrypted_credentials,
                balance=5000.0, equity=5000.0, is_authorized_live=False,
            )
            rejected = asyncio.run(deriv_connector.dispatch_deriv_order_async(live_acct, {
                "instrument": "V75", "direction": "BUY", "lots": 0.1, "requested_price": 235420.5
            }))
            self.assertFalse(rejected["confirmed"])
            self.assertEqual(rejected["status"], "REJECTED_UNAUTHORIZED")
        finally:
            db.close()

        # 4. Verify Deriv token authorization & order execution endpoints with mocked WS responses
        class FakeDerivWS:
            def __init__(self, responses):
                self._responses = list(responses)

            async def __aenter__(self):
                return self

            async def __aexit__(self, exc_type, exc, tb):
                return False

            async def send(self, _data):
                return None

            async def recv(self):
                return json.dumps(self._responses.pop(0))

        with patch("td_trader.backend.app.services.deriv_connector.websockets.connect") as mock_ws:
            mock_ws.return_value = FakeDerivWS([
                {
                    "authorize": {
                        "loginid": "VRTC999888",
                        "balance": 10000.0,
                        "currency": "USD",
                        "is_virtual": 1,
                        "email": "trader@techdaddy.io",
                        "fullname": "TechDaddy Quant",
                        "account_list": [{"loginid": "VRTC999888", "currency": "USD", "is_virtual": 1}],
                    }
                }
            ])
            verify_res = self.client.post("/api/v1/brokers/deriv/verify-token", json={
                "api_token": "deriv_test_token_xyz",
                "app_id": "54321",
            })
            self.assertEqual(verify_res.status_code, 200)
            vdata = verify_res.json()
            self.assertTrue(vdata["verified"])
            self.assertEqual(vdata["loginid"], "VRTC999888")
            self.assertEqual(vdata["recommended_platform"], "DERIV_API_DEMO")

        unique_contract_id = (uuid.uuid4().int % 900000000) + 100000000
        with patch("td_trader.backend.app.services.deriv_connector.websockets.connect") as mock_ws:
            mock_ws.return_value = FakeDerivWS([
                {"authorize": {"loginid": "VRTC999888", "balance": 10000.0, "is_virtual": 1}},
                {"proposal": {"id": "prop_12345", "ask_price": 10.0, "spot": 235420.5}},
                {"buy": {"contract_id": unique_contract_id, "transaction_id": unique_contract_id + 1, "balance_after": 9990.0}},
            ])
            exec_res = self.client.post("/api/v1/trading/execute", json={
                "account_id": acct_id,
                "instrument": "V75",
                "direction": "BUY",
                "lots": 0.1,
                "stop_loss": 233000.0,
                "take_profit": 239000.0,
            })
            self.assertEqual(exec_res.status_code, 200, exec_res.text)
            edata = exec_res.json()
            self.assertEqual(edata["status"], "CONFIRMED_BY_BROKER")
            self.assertEqual(edata["ticket"], f"DERIV_{unique_contract_id}")

        # Verify closing the Deriv contract via WebSocket sell endpoint
        db = SessionLocal()
        try:
            pos = db.query(Position).filter(Position.position_ticket == f"DERIV_{unique_contract_id}").first()
            self.assertIsNotNone(pos)
            pos_id = pos.id
        finally:
            db.close()

        with patch("td_trader.backend.app.services.deriv_connector.websockets.connect") as mock_ws:
            mock_ws.return_value = FakeDerivWS([
                {"authorize": {"loginid": "VRTC999888", "balance": 9990.0, "is_virtual": 1}},
                {"sell": {"sold_for": 15.5, "transaction_id": unique_contract_id + 2}},
            ])
            close_res = self.client.post(f"/api/v1/trading/positions/close/{pos_id}")
            self.assertEqual(close_res.status_code, 200, close_res.text)

        # 5. Verify Backtesting on Deriv Volatility 75 Index
        bt_res = backtest_engine.run_backtest(BacktestRequest(
            strategy_name="MA_Crossover",
            instrument="V75",
            timeframe="H1",
            start_date="2026-01-01",
            end_date="2026-11-01",
            initial_balance=10000.0,
            run_walk_forward=False,
        ))
        self.assertEqual(bt_res.instrument, "V75")
        self.assertIsNotNone(bt_res.win_rate)

if __name__ == "__main__":
    unittest.main()

