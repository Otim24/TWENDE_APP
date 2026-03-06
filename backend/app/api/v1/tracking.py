from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from typing import List, Dict

router = APIRouter()

class ConnectionManager:
    def __init__(self):
        # Map trip_id to list of active web sockets
        self.active_connections: Dict[int, List[WebSocket]] = {}

    async def connect(self, websocket: WebSocket, trip_id: int):
        await websocket.accept()
        if trip_id not in self.active_connections:
            self.active_connections[trip_id] = []
        self.active_connections[trip_id].append(websocket)

    def disconnect(self, websocket: WebSocket, trip_id: int):
        if trip_id in self.active_connections:
            if websocket in self.active_connections[trip_id]:
                self.active_connections[trip_id].remove(websocket)
            if not self.active_connections[trip_id]:
                del self.active_connections[trip_id]

    async def broadcast_location(self, trip_id: int, location_data: dict):
        if trip_id in self.active_connections:
            for connection in self.active_connections[trip_id]:
                await connection.send_json(location_data)

manager = ConnectionManager()

@router.websocket("/ws/{trip_id}")
async def websocket_endpoint(websocket: WebSocket, trip_id: int):
    await manager.connect(websocket, trip_id)
    try:
        while True:
            # Here we just keep the connection open. 
            # Real data would come from an internal event bus (Redis/Celery) 
            # triggered by the Conductor App's GPS updates.
            # For MVP, we might just echo or wait for external triggers.
            data = await websocket.receive_text()
            # If the client sends data (maybe the conductor app?), broadcast it
            # In a real app, Conductor pushes to HTTP POST, Server pushes to WS subscribers.
            # But for simple MVP, if Conductor connects here too, we can relay.
            import json
            try:
                location_update = json.loads(data)
                await manager.broadcast_location(trip_id, location_update)
            except:
                pass 
            
    except WebSocketDisconnect:
        manager.disconnect(websocket, trip_id)
