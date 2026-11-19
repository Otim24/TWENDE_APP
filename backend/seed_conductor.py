import asyncio
from datetime import datetime, timedelta, timezone
from tortoise import Tortoise
from app.core.config import settings
from app.core.security import get_password_hash
from app.models.user_model import User, UserRole
from app.models.wallet_model import Wallet, Transaction
from app.models.bus_model import Bus
from app.models.trip_model import Trip, Route, TripStatus
from app.models.booking_model import Booking


SCHEMA_MIGRATIONS = [
    "ALTER TABLE wallets ADD COLUMN IF NOT EXISTS currency VARCHAR(3) NOT NULL DEFAULT 'UGX';",
    "ALTER TABLE wallets ADD COLUMN IF NOT EXISTS status VARCHAR(8) NOT NULL DEFAULT 'ACTIVE';",
    "ALTER TABLE buses ADD COLUMN IF NOT EXISTS total_seats INT NOT NULL DEFAULT 60;",
    "ALTER TABLE buses ADD COLUMN IF NOT EXISTS seat_layout JSONB NULL;",
    "ALTER TABLE routes ADD COLUMN IF NOT EXISTS stops JSONB NOT NULL DEFAULT '[]'::jsonb;",
    "ALTER TABLE routes ADD COLUMN IF NOT EXISTS polyline TEXT NULL;",
    "ALTER TABLE trips ADD COLUMN IF NOT EXISTS route_id INT NULL;",
    "ALTER TABLE trips ADD COLUMN IF NOT EXISTS bus_id INT NULL;",
    "ALTER TABLE trips ADD COLUMN IF NOT EXISTS arrival_time TIMESTAMPTZ NULL;",
    "ALTER TABLE trips ADD COLUMN IF NOT EXISTS status VARCHAR(10) NOT NULL DEFAULT 'SCHEDULED';",
    "ALTER TABLE bookings ADD COLUMN IF NOT EXISTS qr_code_data VARCHAR(255) NULL;",
]


async def reconcile_legacy_not_null_columns(conn):
    models = [User, Wallet, Transaction, Bus, Route, Trip, Booking]
    for model in models:
        table = model._meta.db_table
        active_cols = set(model._meta.fields_db_projection.values()) | {"id"}
        _, rows = await conn.execute_query(
            """
            SELECT column_name
            FROM information_schema.columns
            WHERE table_schema = 'public'
              AND table_name = $1
              AND is_nullable = 'NO'
              AND column_default IS NULL
            """,
            [table],
        )
        for row in rows:
            col = row["column_name"]
            if col not in active_cols:
                print(f"Dropping legacy NOT NULL constraint on {table}.{col}...")
                await conn.execute_script(f'ALTER TABLE "{table}" ALTER COLUMN "{col}" DROP NOT NULL;')


async def seed():
    print("Connecting to DB...")
    try:
        await Tortoise.init(
            db_url=settings.DATABASE_URL,
            modules={
                "models": [
                    "app.models.user_model",
                    "app.models.wallet_model",
                    "app.models.bus_model",
                    "app.models.trip_model",
                    "app.models.booking_model",
                ]
            },
        )
        print("Generating Schemas...")
        await Tortoise.generate_schemas(safe=True)
        conn = Tortoise.get_connection("default")
        for sql in SCHEMA_MIGRATIONS:
            await conn.execute_script(sql)
        await reconcile_legacy_not_null_columns(conn)
    except Exception as e:
        print(f"DB Init failed: {e}")
        return

    phone = "0700000000"
    password = "1234"
    hashed_password = get_password_hash(password)

    print(f"Checking for user {phone}...")
    user = await User.get_or_none(phone=phone)

    if not user:
        print(f"Creating conductor user: {phone}")
        user = await User.create(
            phone=phone,
            password_hash=hashed_password,
            full_name="Twende Conductor",
            role=UserRole.CONDUCTOR,
        )
        print("Conductor created successfully!")
    else:
        print("User exists. Updating Conductor with bcrypt password hash...")
        user.password_hash = hashed_password
        user.role = UserRole.CONDUCTOR
        if not user.full_name:
            user.full_name = "Twende Conductor"
        await user.save()
        print("Conductor credentials updated!")

    await Wallet.get_or_create(user=user)

    print("Checking for Bus...")
    bus = await Bus.get_or_none(plate_number="UBA 123X")
    if not bus:
        print("Creating Bus UBA 123X...")
        bus = await Bus.create(plate_number="UBA 123X", total_seats=60)

    print("Checking for Route...")
    route = await Route.get_or_none(name="Kampala - Gulu")
    if not route:
        print("Creating Route Kampala - Gulu...")
        route = await Route.create(
            name="Kampala - Gulu",
            origin="Kampala",
            destination="Gulu",
            stops=[
                {"name": "Kampala Bus Terminal", "time_offset": 0},
                {"name": "Luwero Stage", "time_offset": 90},
                {"name": "Karuma Junction", "time_offset": 240},
                {"name": "Gulu Main Park", "time_offset": 360},
            ],
        )

    print("Checking for Trips...")
    now_utc = datetime.now(timezone.utc)
    trip = await Trip.filter(bus=bus, status=TripStatus.SCHEDULED).first()
    if not trip:
        print("Creating Scheduled Trip...")
        await Trip.create(
            route=route,
            bus=bus,
            departure_time=now_utc + timedelta(hours=2),
            arrival_time=now_utc + timedelta(hours=8),
            price=30000,
            status=TripStatus.SCHEDULED,
        )
    elif trip.departure_time <= now_utc:
        print("Refreshing Scheduled Trip departure/arrival times to future UTC...")
        trip.departure_time = now_utc + timedelta(hours=2)
        trip.arrival_time = now_utc + timedelta(hours=8)
        await trip.save()

    print("Data Seed Complete!")
    await Tortoise.close_connections()


if __name__ == "__main__":
    try:
        asyncio.run(seed())
    except Exception as e:
        print(f"Script failed: {e}")
