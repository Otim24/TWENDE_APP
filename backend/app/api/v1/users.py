# pyrefly: ignore [missing-import]
from fastapi import APIRouter, Depends
from app.api.deps import get_current_user
from app.models import User

router = APIRouter()

@router.get("/me")
async def read_users_me(current_user: User = Depends(get_current_user)):
    """
    Get current user profile (for Dashboard greeting).
    """
    return {
        "id": current_user.id,
        "phone": current_user.phone,
        "full_name": current_user.full_name,
        "role": current_user.role,
    }
