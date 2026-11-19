from tortoise import fields, models
from app.models.base import TimestampMixin
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from app.models.trip_model import Trip


class Bus(TimestampMixin, models.Model):
    id = fields.IntField(pk=True)
    plate_number = fields.CharField(max_length=20, unique=True)
    total_seats = fields.IntField(default=60)
    seat_layout = fields.JSONField(null=True)

    trips: fields.ReverseRelation["Trip"]

    class Meta:
        table = "buses"

    def get_valid_seats(self) -> list[int]:
        if isinstance(self.seat_layout, list) and len(self.seat_layout) > 0:
            return [int(s) for s in self.seat_layout]
        return list(range(1, (self.total_seats or 60) + 1))

    @property
    def capacity(self) -> int:
        return len(self.get_valid_seats())

    def __str__(self):
        return self.plate_number
