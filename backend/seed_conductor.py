import asyncio
from tortoise import Tortoise
from app.core.config import settings
from app.models.user_model import User, UserRole
# Reviewing fix_db.py showed us we need to load all models to avoid foreign key issues during init, 
# though for just User we might get away with less, safety first consistently.

async def seed():
    print("Connecting to DB...")
    try:
        await Tortoise.init(
            db_url=settings.DATABASE_URL,
            modules={"models": ["app.models.user_model", "app.models.wallet_model", "app.models.bus_model", "app.models.trip_model", "app.models.booking_model", "app.models.cargo_model"]},
        )
        # Attempt to fix schema if missing
        print("Generating Schemas...")
        await Tortoise.generate_schemas(safe=True)
    except Exception as e:
        print(f"DB Init failed: {e}")
        return

    phone = "0700000000"
    password = "1234"
    
    print(f"Checking for user {phone}...")
    user = await User.get_or_none(phone=phone)
    
    if not user:
        print(f"Creating conductor user: {phone}")
        await User.create(
            phone=phone,
            password_hash=password,
            full_name="Twende Conductor",
            role=UserRole.CONDUCTOR
        )
        print("Conductor created successfully!")
    else:
        print("User exists. Ensuring it is a Conductor with correct password...")
        user.password_hash = password
        user.role = UserRole.CONDUCTOR
        await user.save()
        print("Conductor credentials updated!")

    
    # 2. SEED BUS & ROUTE
    from app.models.bus_model import Bus
    from app.models.trip_model import Trip, Route, TripStatus
    from datetime import datetime, timedelta

    print("Checking for Bus...")
    bus = await Bus.get_or_none(plate_number="UBA 123X")
    if not bus:
         print("Creating Bus UBA 123X...")
         bus = await Bus.create(
             plate_number="UBA 123X",
             total_seats=60
         )
    
    print("Checking for Route...")
    route = await Route.get_or_none(name="Kampala - Gulu")
    if not route:
        print("Creating Route Kampala - Gulu...")
        route = await Route.create(
            name="Kampala - Gulu",
            origin="Kampala",
            destination="Gulu",
            stops=[]
        )

    print("Checking for Trips...")
    # Clean up old scheduled trips for clean slate? No, just ensure one exists.
    trip = await Trip.get_or_none(bus=bus, status=TripStatus.SCHEDULED)
    if not trip:
        print("Creating Scheduled Trip...")
        await Trip.create(
            route=route,
            bus=bus,
            departure_time=datetime.now() + timedelta(hours=2),
            arrival_time=datetime.now() + timedelta(hours=8),
            price=30000,
            status=TripStatus.SCHEDULED
        )
    
    print("Data Seed Complete!")
    await Tortoise.close_connections()

if __name__ == "__main__":
    try:
        asyncio.run(seed())
    except Exception as e:
        print(f"Script failed: {e}")
