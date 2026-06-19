
from fastapi import APIRouter, HTTPException, Depends, status
from app.schemas.auth_schema import Token
from app.core.security import create_access_token, verify_password
from app.models.user_model import User, UserRole
from app.models.wallet_model import Wallet
from app.core.config import settings
from app.services.notification import notification_service
import redis.asyncio as redis
import random
from pydantic import BaseModel

router = APIRouter()

# Simple connection pool for Redis
redis_client = redis.from_url(settings.REDIS_URL, decode_responses=True)

class OTPRequest(BaseModel):
    phone: str

class OTPVerify(BaseModel):
    phone: str
    code: str

@router.post("/otp/request")
async def request_otp(payload: OTPRequest):
    # 1. Generate 6-digit code
    code = str(random.randint(100000, 999999))
    
    # 2. Store in Redis (TTL: 300s = 5 mins)
    await redis_client.setex(f"otp:{payload.phone}", 300, code)
    
    # 3. Send SMS
    await notification_service.send_sms(payload.phone, code)
    
    return {"message": "OTP sent successfully"}

@router.post("/otp/verify", response_model=Token)
async def verify_otp(payload: OTPVerify):
    # 1. Verify Code
    stored_code = await redis_client.get(f"otp:{payload.phone}")
    
    if not stored_code or stored_code != payload.code:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid or expired OTP"
        )
    
    # 2. Find or Create User
    user = await User.get_or_none(phone=payload.phone)
    
    if not user:
        from tortoise.transactions import in_transaction
        
        async with in_transaction():
            # Create new passenger
            user = await User.create(
                phone=payload.phone,
                password_hash="", # No password needed
                role=UserRole.PASSENGER,
                # Default name, can be updated later via /users/me
                full_name="Passenger" 
            )
            # Create Wallet
            await Wallet.create(user=user)

    # 3. Create Token
    access_token = create_access_token(
        data={"sub": str(user.id), "role": user.role.value}
    )
    
    # 4. Clean up OTP
    await redis_client.delete(f"otp:{payload.phone}")
    
    return {"access_token": access_token, "token_type": "bearer"}

class LoginRequest(BaseModel):
    phone: str
    password: str

@router.post("/login", response_model=Token)
async def login(payload: LoginRequest):
    user = await User.get_or_none(phone=payload.phone)
    
    # Simple check for now. In real app, we verify hash.
    # We will assume if password matches plain text or verify_password(payload.password, user.password_hash)
    # Since we set empty password for passengers, Conductors need to be seeded with a password.
    # For MVP: If user exists and role is CONDUCTOR, we verify password.
    
    if not user:
         raise HTTPException(status_code=400, detail="Invalid credentials")

    if not verify_password(payload.password, user.password_hash):
        raise HTTPException(status_code=400, detail="Invalid credentials")

    access_token = create_access_token(
        data={"sub": str(user.id), "role": user.role.value}
    )
    return {"access_token": access_token, "token_type": "bearer", "user_name": user.full_name}
