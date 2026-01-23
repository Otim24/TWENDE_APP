from enum import Enum
from tortoise import fields, models
from app.models.base import TimestampMixin

class BookingStatus(str, Enum):
    LOCKED = "LOCKED"
    PAID = "PAID"
    CANCELLED = "CANCELLED"
    USED = "USED"

class Booking(TimestampMixin, models.Model):
    id = fields.IntField(pk=True)
    trip = fields.ForeignKeyField("models.Trip", related_name="bookings")
    user = fields.ForeignKeyField("models.User", related_name="bookings")
    seat_number = fields.IntField()
    status = fields.CharEnumField(BookingStatus, default=BookingStatus.LOCKED)
    qr_code_data = fields.CharField(max_length=255, null=True)

    class Meta:
        table = "bookings"
        unique_together = (("trip", "seat_number"),)

    def __str__(self):
        return f"Booking {self.id} (Seat {self.seat_number})"
