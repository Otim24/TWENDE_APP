from enum import Enum
from tortoise import fields, models
from app.models.base import TimestampMixin

class UserRole(str, Enum):
    PASSENGER = "PASSENGER"
    CONDUCTOR = "CONDUCTOR"
    ADMIN = "ADMIN"

class User(TimestampMixin, models.Model):
    id = fields.IntField(pk=True)
    phone = fields.CharField(max_length=20, unique=True)
    password_hash = fields.CharField(max_length=255)
    full_name = fields.CharField(max_length=100, null=True)
    role = fields.CharEnumField(UserRole, default=UserRole.PASSENGER)

    # Reverse relations
    wallet: fields.ReverseRelation["Wallet"]
    bookings: fields.ReverseRelation["Booking"]

    class Meta:
        table = "users"

    def __str__(self):
        return f"{self.full_name} ({self.phone})"
