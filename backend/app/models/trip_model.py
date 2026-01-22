from enum import Enum
from tortoise import fields, models
from app.models.base import TimestampMixin

class TripStatus(str, Enum):
    SCHEDULED = "SCHEDULED"
    BOARDING = "BOARDING"
    DEPARTED = "DEPARTED"
    COMPLETED = "COMPLETED"
    CANCELLED = "CANCELLED"

class Route(TimestampMixin, models.Model):
    id = fields.IntField(pk=True)
    name = fields.CharField(max_length=100) # e.g. "Kampala - Busia"
    origin = fields.CharField(max_length=100)
    destination = fields.CharField(max_length=100)
    stops = fields.JSONField(default=[]) # List of stops: [{"name": "Mukono", "time_offset": 30}, ...]
    
    trips: fields.ReverseRelation["Trip"]

    class Meta:
        table = "routes"

    def __str__(self):
        return self.name

class Trip(TimestampMixin, models.Model):
    id = fields.IntField(pk=True)
    route = fields.ForeignKeyField("models.Route", related_name="trips")
    bus = fields.ForeignKeyField("models.Bus", related_name="trips")
    
    departure_time = fields.DatetimeField()
    arrival_time = fields.DatetimeField()
    price = fields.DecimalField(max_digits=10, decimal_places=2)
    status = fields.CharEnumField(TripStatus, default=TripStatus.SCHEDULED)
    
    # Snapshot of route at time of creation (optional, but good for history)
    
    bookings: fields.ReverseRelation["Booking"]

    class Meta:
        table = "trips"

    def __str__(self):
        return f"{self.route.name} ({self.departure_time})"
