from fastapi import APIRouter, Depends, HTTPException
from app.api.deps import get_current_user
from app.models import User, Wallet

router = APIRouter()

@router.get("/balance")
async def get_wallet_balance(current_user: User = Depends(get_current_user)):
    """
    Get current user's wallet balance.
    """
    wallet = await Wallet.get_or_none(user=current_user)
    
    if not wallet:
        # Should not happen due to atomic auth, but safety first
        wallet = await Wallet.create(user=current_user)
    
    return {
        "balance": wallet.balance,
        "currency": wallet.currency,
        "status": wallet.status
    }
