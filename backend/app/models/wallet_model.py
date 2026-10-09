from enum import Enum
from tortoise import fields, models
from app.models.base import TimestampMixin

class Wallet(TimestampMixin, models.Model):
    id = fields.IntField(pk=True)
    user = fields.OneToOneField("models.User", related_name="wallet")
    balance = fields.DecimalField(max_digits=12, decimal_places=2, default=0.00)
    currency = fields.CharField(max_length=3, default="UGX")
    status = fields.CharField(max_length=8, default="ACTIVE")

    class Meta:
        table = "wallets"

    def __str__(self):
        return f"Wallet {self.id} (User: {self.user_id})"

class TransactionType(str, Enum):
    DEPOSIT = "DEPOSIT"
    WITHDRAWAL = "WITHDRAWAL"
    PAYMENT = "PAYMENT"
    REFUND = "REFUND"

class TransactionStatus(str, Enum):
    PENDING = "PENDING"
    COMPLETED = "COMPLETED"
    FAILED = "FAILED"

class Transaction(TimestampMixin, models.Model):
    id = fields.IntField(pk=True)
    wallet = fields.ForeignKeyField("models.Wallet", related_name="transactions")
    amount = fields.DecimalField(max_digits=12, decimal_places=2)
    type = fields.CharEnumField(TransactionType)
    status = fields.CharEnumField(TransactionStatus, default=TransactionStatus.PENDING)
    reference = fields.CharField(max_length=100) # e.g. "MOMO-123" or "BOOKING-456"

    class Meta:
        table = "transactions"

    def __str__(self):
        return f"{self.type} {self.amount} ({self.status})"
