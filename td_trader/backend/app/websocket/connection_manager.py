"""TD TRADER - Real-Time WebSocket Event Broker
Manages authenticated real-time pub/sub streams for signals, orders, positions,
risk guardian breach alerts, and voice announcements.
"""

from typing import Dict, List, Set, Any
import json
import asyncio
from datetime import datetime
from starlette.websockets import WebSocket

class WebSocketConnectionManager:
    """Enterprise WebSocket manager supporting per-user channels and event multicasting."""
    
    def __init__(self):
        # Maps user_id -> set of active WebSockets
        self.active_user_connections: Dict[int, Set[WebSocket]] = {}
        # Global broadcast connections (e.g. market ticks & public signals)
        self.broadcast_connections: Set[WebSocket] = set()

    async def connect(self, websocket: WebSocket, user_id: int):
        await websocket.accept()
        if user_id not in self.active_user_connections:
            self.active_user_connections[user_id] = set()
        self.active_user_connections[user_id].add(websocket)
        self.broadcast_connections.add(websocket)

    def disconnect(self, websocket: WebSocket, user_id: int):
        if user_id in self.active_user_connections:
            self.active_user_connections[user_id].discard(websocket)
            if not self.active_user_connections[user_id]:
                del self.active_user_connections[user_id]
        self.broadcast_connections.discard(websocket)

    async def broadcast_event(self, event_type: str, data: Dict[str, Any]):
        """Broadcasts event across all connected clients."""
        payload = {
            "event": event_type,
            "data": data,
            "timestamp": datetime.utcnow().isoformat()
        }
        raw_msg = json.dumps(payload)
        stale_connections = set()
        
        for ws in self.broadcast_connections:
            try:
                await ws.send_text(raw_msg)
            except Exception:
                stale_connections.add(ws)
                
        for stale in stale_connections:
            self.broadcast_connections.discard(stale)

    async def send_user_event(self, user_id: int, event_type: str, data: Dict[str, Any]):
        """Delivers event directly to specific authenticated user."""
        if user_id not in self.active_user_connections:
            return
            
        payload = {
            "event": event_type,
            "data": data,
            "timestamp": datetime.utcnow().isoformat()
        }
        raw_msg = json.dumps(payload)
        stale = set()
        
        for ws in self.active_user_connections[user_id]:
            try:
                await ws.send_text(raw_msg)
            except Exception:
                stale.add(ws)
                
        for s in stale:
            self.active_user_connections[user_id].discard(s)

ws_manager = WebSocketConnectionManager()

