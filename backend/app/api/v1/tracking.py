import json
from typing import Dict, List, Optional
from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from jose import JWTError, jwt
from pydantic import BaseModel, Field, ValidationError

from app.core.config import settings
from app.core.security import ALGORITHM
from app.models.user_model import User, UserRole
from app.schemas.auth_schema import TokenPayload

router = APIRouter()


class LocationUpdatePayload(BaseModel):
    lat: float = Field(..., ge=-90.0, le=90.0)
    lng: float = Field(..., ge=-180.0, le=180.0)
    speed: Optional[float] = Field(default=None, ge=0.0)
    heading: Optional[float] = Field(default=None, ge=0.0, le=360.0)


class ConnectionManager:
    def __init__(self):
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
            stale: List[WebSocket] = []
            for connection in list(self.active_connections[trip_id]):
                try:
                    await connection.send_json(location_data)
                except Exception:
                    stale.append(connection)
            for s in stale:
                self.disconnect(s, trip_id)


manager = ConnectionManager()


async def _resolve_ws_role(websocket: WebSocket) -> Optional[UserRole]:
    token = websocket.query_params.get("token")
    if not token:
        auth_header = websocket.headers.get("authorization") or websocket.headers.get("Authorization")
        if auth_header and auth_header.lower().startswith("bearer "):
            token = auth_header.split(" ", 1)[1].strip()
    if not token:
        return None
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[ALGORITHM])
        token_data = TokenPayload(**payload)
        if not token_data.sub:
            return None
        user = await User.get_or_none(id=token_data.sub)
        return user.role if user else None
    except (JWTError, ValidationError):
        return None


async def _handle_tracking_ws(websocket: WebSocket, trip_id: int):
    role = await _resolve_ws_role(websocket)
    await manager.connect(websocket, trip_id)
    try:
        while True:
            data = await websocket.receive_text()
            if role != UserRole.CONDUCTOR:
                await websocket.send_json(
                    {"error": "Unauthorized: Conductor role required to broadcast GPS"}
                )
                continue
            try:
                raw_obj = json.loads(data)
                validated = LocationUpdatePayload(**raw_obj)
                await manager.broadcast_location(
                    trip_id,
                    validated.model_dump(exclude_none=True),
                )
            except (json.JSONDecodeError, ValidationError):
                await websocket.send_json({"error": "Invalid GPS payload format"})
    except WebSocketDisconnect:
        manager.disconnect(websocket, trip_id)


@router.websocket("/{trip_id}")
async def websocket_root_endpoint(websocket: WebSocket, trip_id: int):
    await _handle_tracking_ws(websocket, trip_id)


@router.websocket("/ws/{trip_id}")
async def websocket_ws_endpoint(websocket: WebSocket, trip_id: int):
    await _handle_tracking_ws(websocket, trip_id)
