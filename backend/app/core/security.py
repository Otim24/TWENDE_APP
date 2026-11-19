from datetime import datetime, timedelta, timezone
import hashlib
import hmac
from typing import Optional
import bcrypt
from jose import jwt
from app.core.config import settings

ALGORITHM = "HS256"


def verify_password(plain_password: str, hashed_password: str) -> bool:
    if not plain_password or not hashed_password:
        return False
    try:
        return bcrypt.checkpw(
            plain_password.encode("utf-8")[:72],
            hashed_password.encode("utf-8"),
        )
    except (ValueError, TypeError):
        return False


def get_password_hash(password: str) -> str:
    hashed = bcrypt.hashpw(
        password.encode("utf-8")[:72],
        bcrypt.gensalt(),
    )
    return hashed.decode("utf-8")


def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.now(timezone.utc) + expires_delta
    else:
        expire = datetime.now(timezone.utc) + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)

    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt


def generate_ticket_qr_data(trip_id: int, seat_number: int) -> str:
    raw_payload = f"TICKET-{trip_id}-{seat_number}"
    signature = hmac.new(
        settings.SECRET_KEY.encode("utf-8"),
        raw_payload.encode("utf-8"),
        hashlib.sha256,
    ).hexdigest()
    return f"{raw_payload}:{signature}"
