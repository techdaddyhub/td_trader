"""TD TRADER - Main ASGI Application
Production ASGI server with CORS, WebSockets, background scanner tasks, and API route routing.
"""

import asyncio
from contextlib import asynccontextmanager
from starlette.applications import Starlette
from starlette.middleware import Middleware
from starlette.middleware.cors import CORSMiddleware
from starlette.routing import Route, WebSocketRoute
from starlette.responses import JSONResponse

from td_trader.backend.app.core.config import settings
from td_trader.backend.app.models.entities import init_db
from td_trader.ai_engine.market_scanner.scanner import ai_market_scanner
from td_trader.backend.app.api.endpoints import (
    register_user, login_user, get_current_user_profile,
    get_scanner_opportunities, trigger_scanner_refresh, get_live_quotes, get_ohlcv_data,
    voice_query_handler, get_voice_personalities, test_voice_announcement,
    get_risk_config, update_risk_config, execute_emergency_control,
    run_backtest_handler, compare_strategies_handler, list_available_strategies,
    list_trading_accounts, create_trading_account, toggle_auto_trading, authorize_live_account,
    get_portfolio_summary_handler, submit_order_handler, get_positions_handler, close_position_handler,
    verify_deriv_token_handler, list_deriv_instruments_handler, sync_deriv_market_data_handler,
    list_journal_entries, websocket_endpoint
)

async def root_status(request):
    return JSONResponse({
        "project": settings.PROJECT_NAME,
        "tagline": settings.TAGLINE,
        "version": settings.VERSION,
        "owner": settings.OWNER,
        "organization": settings.ORGANIZATION,
        "copyright": settings.COPYRIGHT,
        "status": "OPERATIONAL",
        "core_modules": [
            "1. AI Multi-Market Scanner",
            "2. TD AI Voice - Personal Trading Analyst",
            "3. Smart Risk Guardian",
            "4. AI Strategy Backtester",
            "5. Multi-Account Manager"
        ],
        "endpoints": {
            "api_prefix": settings.API_PREFIX,
            "websocket": "/ws"
        }
    })

routes = [
    # System Status
    Route("/", root_status, methods=["GET"]),
    Route("/health", root_status, methods=["GET"]),
    
    # Auth
    Route(f"{settings.API_PREFIX}/auth/register", register_user, methods=["POST"]),
    Route(f"{settings.API_PREFIX}/auth/login", login_user, methods=["POST"]),
    Route(f"{settings.API_PREFIX}/auth/me", get_current_user_profile, methods=["GET"]),
    
    # Module 1: AI Multi-Market Scanner
    Route(f"{settings.API_PREFIX}/scanner/opportunities", get_scanner_opportunities, methods=["GET"]),
    Route(f"{settings.API_PREFIX}/scanner/scan-now", trigger_scanner_refresh, methods=["POST"]),
    Route(f"{settings.API_PREFIX}/scanner/quotes", get_live_quotes, methods=["GET"]),
    Route(f"{settings.API_PREFIX}/scanner/ohlcv/{{symbol}}", get_ohlcv_data, methods=["GET"]),
    
    # Module 2: TD AI Voice
    Route(f"{settings.API_PREFIX}/voice/query", voice_query_handler, methods=["POST"]),
    Route(f"{settings.API_PREFIX}/voice/personalities", get_voice_personalities, methods=["GET"]),
    Route(f"{settings.API_PREFIX}/voice/test-announcement/{{type}}", test_voice_announcement, methods=["POST"]),
    
    # Module 3: Smart Risk Guardian
    Route(f"{settings.API_PREFIX}/risk/config/{{account_id:int}}", get_risk_config, methods=["GET"]),
    Route(f"{settings.API_PREFIX}/risk/config/{{account_id:int}}", update_risk_config, methods=["PUT"]),
    Route(f"{settings.API_PREFIX}/risk/emergency-action/{{account_id:int}}", execute_emergency_control, methods=["POST"]),
    
    # Module 4: AI Strategy Backtester
    Route(f"{settings.API_PREFIX}/backtest/run", run_backtest_handler, methods=["POST"]),
    Route(f"{settings.API_PREFIX}/backtest/compare", compare_strategies_handler, methods=["POST"]),
    Route(f"{settings.API_PREFIX}/backtest/strategies", list_available_strategies, methods=["GET"]),
    
    # Module 5: Multi-Account Manager & Trading
    Route(f"{settings.API_PREFIX}/accounts/", list_trading_accounts, methods=["GET"]),
    Route(f"{settings.API_PREFIX}/accounts/", create_trading_account, methods=["POST"]),
    Route(f"{settings.API_PREFIX}/accounts/{{id:int}}/toggle-auto-trading", toggle_auto_trading, methods=["PUT"]),
    Route(f"{settings.API_PREFIX}/accounts/{{id:int}}/authorize-live", authorize_live_account, methods=["PUT"]),
    Route(f"{settings.API_PREFIX}/accounts/portfolio/summary", get_portfolio_summary_handler, methods=["GET"]),
    Route(f"{settings.API_PREFIX}/trading/execute", submit_order_handler, methods=["POST"]),
    Route(f"{settings.API_PREFIX}/trading/positions/{{account_id:int}}", get_positions_handler, methods=["GET"]),
    Route(f"{settings.API_PREFIX}/trading/positions/close/{{position_id:int}}", close_position_handler, methods=["POST"]),
    
    # Trading Journal
    Route(f"{settings.API_PREFIX}/journal/", list_journal_entries, methods=["GET"]),

    # Deriv Broker Integration
    Route(f"{settings.API_PREFIX}/brokers/deriv/verify-token", verify_deriv_token_handler, methods=["POST"]),
    Route(f"{settings.API_PREFIX}/brokers/deriv/instruments", list_deriv_instruments_handler, methods=["GET"]),
    Route(f"{settings.API_PREFIX}/brokers/deriv/sync-ticks", sync_deriv_market_data_handler, methods=["POST"]),

    # WebSocket Real-Time Event Bus
    WebSocketRoute("/ws", websocket_endpoint)
]

middleware = [
    Middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_methods=["*"],
        allow_headers=["*"],
        allow_credentials=True
    )
]

@asynccontextmanager
async def lifespan(app):
    init_db()
    # Pre-warm scanner
    asyncio.create_task(asyncio.to_thread(ai_market_scanner.scan_all_markets))
    yield

app = Starlette(
    debug=True,
    routes=routes,
    middleware=middleware,
    lifespan=lifespan
)


