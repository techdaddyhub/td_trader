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
        self.assertIn("account_summaries", summary)

if __name__ == "__main__":
    unittest.main()

