# pyrefly: ignore [missing-import]
from fastapi import APIRouter, Depends
from app.api.deps import get_current_user
from app.models import User

router = APIRouter()

from pydantic import BaseModel

class UserResponse(BaseModel):
    full_name: str
    role: str

@router.get("/me", response_model=UserResponse)
async def read_users_me(current_user: User = Depends(get_current_user)):
    """
    Get current user profile (for Dashboard greeting).
    """
    return UserResponse(
        full_name=current_user.full_name,
        role=current_user.role,
    )
