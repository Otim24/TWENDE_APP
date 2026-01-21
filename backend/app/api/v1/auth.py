
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from tortoise.transactions import in_atomic_block

from app.schemas.auth_schema import UserCreate, Token
from app.models.user_model import User
from app.models.wallet_model import Wallet
from app.core.security import verify_password, get_password_hash, create_access_token

router = APIRouter()
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/login")

@router.post("/signup", response_model=Token)
async def signup(user_in: UserCreate):
    # Check if user exists
    if await User.get_or_none(phone=user_in.phone):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Phone number already registered"
        )

    password_hash = get_password_hash(user_in.password)

    # Transaction: Create User + Wallet
    async with in_atomic_block():
        user = await User.create(
            phone=user_in.phone,
            password_hash=password_hash,
            full_name=user_in.full_name,
            role=user_in.role
        )
        # Create Wallet for user
        await Wallet.create(user=user)

    # Generate Token
    access_token = create_access_token(
        data={"sub": str(user.id), "role": user.role.value}
    )
    return {"access_token": access_token, "token_type": "bearer"}

@router.post("/login", response_model=Token)
async def login(form_data: OAuth2PasswordRequestForm = Depends()):
    user = await User.get_or_none(phone=form_data.username)
    if not user or not verify_password(form_data.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect phone or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    access_token = create_access_token(
        data={"sub": str(user.id), "role": user.role.value}
    )
    return {"access_token": access_token, "token_type": "bearer"}
