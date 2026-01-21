from tortoise import fields, models
from app.models.base import TimestampMixin

class Bus(TimestampMixin, models.Model):
    id = fields.IntField(pk=True)
    plate_number = fields.CharField(max_length=20, unique=True)
    total_seats = fields.IntField(default=60)

    trips: fields.ReverseRelation["Trip"]

    class Meta:
        table = "buses"

    def __str__(self):
        return self.plate_number

class Trip(TimestampMixin, models.Model):
    id = fields.IntField(pk=True)
    bus = fields.ForeignKeyField("models.Bus", related_name="trips")
    route_name = fields.CharField(max_length=100) # e.g. "Kampala - Jinja"
    price = fields.DecimalField(max_digits=10, decimal_places=2)
    departure_time = fields.DatetimeField()
    is_active = fields.BooleanField(default=True)

    bookings: fields.ReverseRelation["Booking"]

    class Meta:
        table = "trips"

    def __str__(self):
        return f"{self.route_name} ({self.departure_time})"
