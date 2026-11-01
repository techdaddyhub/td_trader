"""TD TRADER - Asynchronous Background Market Scanner Worker
Continuously scans connected financial feeds, updates ranking scores,
and dispatches real-time WebSocket events.
"""

import asyncio
from datetime import datetime
from td_trader.ai_engine.market_scanner.scanner import ai_market_scanner
from td_trader.backend.app.websocket.connection_manager import ws_manager
from td_trader.backend.app.core.config import settings

class MarketScannerWorker:
    def __init__(self, interval_seconds: int = 10):
        self.interval = interval_seconds
        self._running = False

    async def start(self):
        self._running = True
        print(f"[WORKER] AI Multi-Market Scanner background worker started (interval: {self.interval}s)")
        while self._running:
            try:
                opps = await asyncio.to_thread(ai_market_scanner.scan_all_markets)
                if opps:
                    top = opps[0]
                    # Broadcast top opportunity to connected WebSocket clients
                    await ws_manager.broadcast_event(
                        "NEW_MARKET_SIGNAL",
                        top.model_dump(mode="json")
                    )
            except Exception as e:
                print(f"[WORKER ERROR] Scanner worker cycle error: {e}")
            await asyncio.sleep(self.interval)

    def stop(self):
        self._running = False

scanner_worker = MarketScannerWorker(settings.SCANNER_INTERVAL_SECONDS)

