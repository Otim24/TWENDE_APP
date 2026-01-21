from tortoise import fields, models
from app.models.base import TimestampMixin

class Wallet(TimestampMixin, models.Model):
    id = fields.IntField(pk=True)
    user = fields.OneToOneField("models.User", related_name="wallet")
    balance = fields.DecimalField(max_digits=12, decimal_places=2, default=0.00)

    class Meta:
        table = "wallets"

    def __str__(self):
        return f"Wallet {self.id} (User: {self.user_id})"
