from decimal import Decimal
from typing import Optional
import uuid
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, condecimal
from tortoise.transactions import in_transaction

from app.api.deps import get_current_user
from app.models import User, Wallet
from app.models.wallet_model import Transaction, TransactionStatus, TransactionType

router = APIRouter()


class WalletDepositRequest(BaseModel):
    amount: condecimal(gt=Decimal("0.00"), max_digits=12, decimal_places=2)
    provider: Optional[str] = "MOMO"
    reference: Optional[str] = None


@router.get("/balance")
async def get_wallet_balance(current_user: User = Depends(get_current_user)):
    """
    Get current user's wallet balance.
    """
    wallet, _ = await Wallet.get_or_create(user=current_user)
    return {
        "balance": wallet.balance,
        "currency": wallet.currency,
        "status": wallet.status,
    }


@router.post("/deposit")
async def deposit_wallet(
    payload: WalletDepositRequest,
    current_user: User = Depends(get_current_user),
):
    """
    Deposit funds into the authenticated user's wallet atomically with row-level locking.
    """
    deposit_amount = Decimal(str(payload.amount))
    tx_ref = (
        payload.reference.strip()
        if payload.reference and payload.reference.strip()
        else f"{(payload.provider or 'MOMO').upper()}-{uuid.uuid4().hex[:10].upper()}"
    )

    async with in_transaction():
        wallet = await Wallet.filter(user=current_user).select_for_update().first()
        if not wallet:
            wallet = await Wallet.create(user=current_user, balance=Decimal("0.00"))
            wallet = await Wallet.filter(id=wallet.id).select_for_update().first()

        if wallet.status != "ACTIVE":
            raise HTTPException(status_code=400, detail="Wallet is not active")

        wallet.balance = Decimal(str(wallet.balance)) + deposit_amount
        await wallet.save()

        tx = await Transaction.create(
            wallet=wallet,
            amount=deposit_amount,
            type=TransactionType.DEPOSIT,
            status=TransactionStatus.COMPLETED,
            reference=tx_ref,
        )

    return {
        "success": True,
        "transaction_id": tx.id,
        "reference": tx.reference,
        "deposited_amount": deposit_amount,
        "balance": wallet.balance,
        "currency": wallet.currency,
        "status": wallet.status,
    }
