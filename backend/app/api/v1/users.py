from typing import Optional
from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field
from app.api.deps import get_current_user
from app.models import User

router = APIRouter()


class UserResponse(BaseModel):
    id: Optional[int] = None
    phone: Optional[str] = None
    full_name: Optional[str] = None
    role: str


class UserUpdate(BaseModel):
    full_name: str = Field(..., min_length=1, max_length=100)


@router.get("/me", response_model=UserResponse)
async def read_users_me(current_user: User = Depends(get_current_user)):
    """
    Get current user profile (for Dashboard greeting).
    """
    return UserResponse(
        id=current_user.id,
        phone=current_user.phone,
        full_name=current_user.full_name,
        role=current_user.role.value if hasattr(current_user.role, "value") else str(current_user.role),
    )


@router.patch("/me", response_model=UserResponse)
async def update_users_me(payload: UserUpdate, current_user: User = Depends(get_current_user)):
    """
    Update current user's profile fields.
    """
    current_user.full_name = payload.full_name.strip()
    await current_user.save()
    return UserResponse(
        id=current_user.id,
        phone=current_user.phone,
        full_name=current_user.full_name,
        role=current_user.role.value if hasattr(current_user.role, "value") else str(current_user.role),
    )
