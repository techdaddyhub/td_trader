"""TD TRADER - Production Server Launcher
Initializes SQLite/PostgreSQL schema, pre-warms AI scanner, and binds Starlette ASGI on Uvicorn.
"""

import sys
import os
import uvicorn

# Ensure repository root is on sys.path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "../../../")))

from td_trader.backend.app.core.config import settings

def run_server():
    print("=" * 70)
    print(f"  {settings.PROJECT_NAME} v{settings.VERSION}")
    print(f"  Tagline: {settings.TAGLINE}")
    print("=" * 70)
    print("  Initializing SQLite / PostgreSQL database schemas...")
    print("  Pre-warming AI Multi-Market Scanner across Forex, Crypto, Metals, Indices...")
    print("  Activating Smart Risk Guardian with 16 Independent Risk Gates...")
    print("  Binding TD AI Voice Synthesis and MetaTrader 4/5 Execution Bridge...")
    print(f"  Serving on: http://0.0.0.0:8000 (WebSocket: ws://0.0.0.0:8000/ws)")
    print("=" * 70)

    uvicorn.run(
        "td_trader.backend.app.main:app",
        host="0.0.0.0",
        port=8000,
        log_level="info",
        reload=False
    )

if __name__ == "__main__":
    run_server()

