from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel
import redis.asyncio as redis
from redis.exceptions import RedisError
import secrets
from tortoise.exceptions import IntegrityError
from tortoise.transactions import in_transaction

from app.schemas.auth_schema import Token
from app.core.security import create_access_token, verify_password
from app.models.user_model import User, UserRole
from app.models.wallet_model import Wallet
from app.core.config import settings
from app.services.notification import notification_service

router = APIRouter()

redis_client = redis.from_url(settings.REDIS_URL, decode_responses=True)

OTP_TTL_SECONDS = 300
OTP_COOLDOWN_SECONDS = 60
OTP_MAX_ATTEMPTS = 5


class OTPRequest(BaseModel):
    phone: str


class OTPVerify(BaseModel):
    phone: str
    code: str


@router.post("/otp/request")
async def request_otp(payload: OTPRequest):
    cooldown_key = f"otp_cooldown:{payload.phone}"
    otp_key = f"otp:{payload.phone}"
    attempts_key = f"otp_attempts:{payload.phone}"

    code = str(secrets.randbelow(900000) + 100000)

    try:
        acquired = await redis_client.set(cooldown_key, "1", ex=OTP_COOLDOWN_SECONDS, nx=True)
        if not acquired:
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail="Please wait 60 seconds before requesting another OTP.",
            )
        await redis_client.setex(otp_key, OTP_TTL_SECONDS, code)
        await redis_client.delete(attempts_key)
    except RedisError:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Service temporarily unavailable. Please try again later.",
        )

    await notification_service.send_sms(payload.phone, code)
    return {"message": "OTP sent successfully"}


@router.post("/otp/verify", response_model=Token)
async def verify_otp(payload: OTPVerify):
    otp_key = f"otp:{payload.phone}"
    attempts_key = f"otp_attempts:{payload.phone}"

    try:
        attempts_raw = await redis_client.get(attempts_key)
        attempts = int(attempts_raw) if attempts_raw else 0
        if attempts >= OTP_MAX_ATTEMPTS:
            await redis_client.delete(otp_key)
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail="Too many failed OTP attempts. Please request a new OTP.",
            )

        stored_code = await redis_client.get(otp_key)
        if not stored_code or not secrets.compare_digest(str(stored_code), str(payload.code)):
            new_attempts = await redis_client.incr(attempts_key)
            await redis_client.expire(attempts_key, OTP_TTL_SECONDS)
            if new_attempts >= OTP_MAX_ATTEMPTS:
                await redis_client.delete(otp_key)
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid or expired OTP",
            )

        # Immediately consume OTP on valid match
        await redis_client.delete(otp_key, attempts_key)
    except RedisError:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Service temporarily unavailable. Please try again later.",
        )

    async with in_transaction():
        user = await User.filter(phone=payload.phone).select_for_update().first()
        if user and user.role != UserRole.PASSENGER:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Forbidden: Use password login",
            )
        if not user:
            try:
                user = await User.create(
                    phone=payload.phone,
                    password_hash="",
                    role=UserRole.PASSENGER,
                    full_name="Passenger",
                )
            except IntegrityError:
                user = await User.get(phone=payload.phone)
                if user.role != UserRole.PASSENGER:
                    raise HTTPException(
                        status_code=status.HTTP_403_FORBIDDEN,
                        detail="Forbidden: Use password login",
                    )
        await Wallet.get_or_create(user=user)

    access_token = create_access_token(
        data={"sub": str(user.id), "role": user.role.value}
    )
    return {"access_token": access_token, "token_type": "bearer", "user_name": user.full_name}


class LoginRequest(BaseModel):
    phone: str
    password: str


@router.post("/login", response_model=Token)
async def login(payload: LoginRequest):
    user = await User.get_or_none(phone=payload.phone)
    if not user or not user.password_hash:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid credentials")

    if not verify_password(payload.password, user.password_hash):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid credentials")

    access_token = create_access_token(
        data={"sub": str(user.id), "role": user.role.value}
    )
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user_name": user.full_name,
    }
