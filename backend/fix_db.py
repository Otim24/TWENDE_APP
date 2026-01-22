import asyncio
from tortoise import Tortoise
from app.core.config import settings

SQL_COMMANDS = [
    """
    CREATE TABLE IF NOT EXISTS "users" (
        "id" SERIAL NOT NULL PRIMARY KEY,
        "created_at" TIMESTAMPTZ NOT NULL  DEFAULT CURRENT_TIMESTAMP,
        "updated_at" TIMESTAMPTZ NOT NULL  DEFAULT CURRENT_TIMESTAMP,
        "phone" VARCHAR(20) NOT NULL UNIQUE,
        "password_hash" VARCHAR(255) NOT NULL,
        "full_name" VARCHAR(100),
        "role" VARCHAR(9) NOT NULL  DEFAULT 'PASSENGER'
    );
    """,
    """
    CREATE TABLE IF NOT EXISTS "wallets" (
        "id" SERIAL NOT NULL PRIMARY KEY,
        "created_at" TIMESTAMPTZ NOT NULL  DEFAULT CURRENT_TIMESTAMP,
        "updated_at" TIMESTAMPTZ NOT NULL  DEFAULT CURRENT_TIMESTAMP,
        "balance" DECIMAL(12,2) NOT NULL  DEFAULT 0.00,
        "currency" VARCHAR(3) NOT NULL  DEFAULT 'UGX',
        "status" VARCHAR(8) NOT NULL  DEFAULT 'ACTIVE',
        "user_id" INT NOT NULL UNIQUE REFERENCES "users" ("id") ON DELETE CASCADE
    );
    """,
    """
    CREATE TABLE IF NOT EXISTS "buses" (
        "id" SERIAL NOT NULL PRIMARY KEY,
        "created_at" TIMESTAMPTZ NOT NULL  DEFAULT CURRENT_TIMESTAMP,
        "updated_at" TIMESTAMPTZ NOT NULL  DEFAULT CURRENT_TIMESTAMP,
        "plate_number" VARCHAR(20) NOT NULL UNIQUE,
        "total_seats" INT NOT NULL  DEFAULT 60
    );
    """,
    """
    CREATE TABLE IF NOT EXISTS "routes" (
        "id" SERIAL NOT NULL PRIMARY KEY,
        "created_at" TIMESTAMPTZ NOT NULL  DEFAULT CURRENT_TIMESTAMP,
        "updated_at" TIMESTAMPTZ NOT NULL  DEFAULT CURRENT_TIMESTAMP,
        "name" VARCHAR(100) NOT NULL,
        "origin" VARCHAR(100) NOT NULL,
        "destination" VARCHAR(100) NOT NULL,
        "stops" JSONB NOT NULL DEFAULT '[]'
    );
    """,
    """
    CREATE TABLE IF NOT EXISTS "trips" (
        "id" SERIAL NOT NULL PRIMARY KEY,
        "created_at" TIMESTAMPTZ NOT NULL  DEFAULT CURRENT_TIMESTAMP,
        "updated_at" TIMESTAMPTZ NOT NULL  DEFAULT CURRENT_TIMESTAMP,
        "departure_time" TIMESTAMPTZ NOT NULL,
        "arrival_time" TIMESTAMPTZ NOT NULL,
        "price" DECIMAL(10,2) NOT NULL,
        "status" VARCHAR(9) NOT NULL  DEFAULT 'SCHEDULED',
        "bus_id" INT NOT NULL REFERENCES "buses" ("id") ON DELETE CASCADE,
        "route_id" INT NOT NULL REFERENCES "routes" ("id") ON DELETE CASCADE
    );
    """,
    """
    CREATE TABLE IF NOT EXISTS "bookings" (
        "id" SERIAL NOT NULL PRIMARY KEY,
        "created_at" TIMESTAMPTZ NOT NULL  DEFAULT CURRENT_TIMESTAMP,
        "updated_at" TIMESTAMPTZ NOT NULL  DEFAULT CURRENT_TIMESTAMP,
        "seat_number" INT NOT NULL,
        "status" VARCHAR(9) NOT NULL  DEFAULT 'LOCKED',
        "qr_code_data" VARCHAR(255),
        "trip_id" INT NOT NULL REFERENCES "trips" ("id") ON DELETE CASCADE,
        "user_id" INT NOT NULL REFERENCES "users" ("id") ON DELETE CASCADE,
        CONSTRAINT "uid_bookings_trip_id_4ed05f" UNIQUE ("trip_id", "seat_number")
    );
    """
]

async def init():
    print("Connecting to DB...")
    await Tortoise.init(
        db_url=settings.DATABASE_URL,
        modules={"models": []} # No models needed for raw SQL
    )
    
    conn = Tortoise.get_connection("default")
    
    print("Executing Manual Schema Creation...")
    for i, sql in enumerate(SQL_COMMANDS):
        print(f"Creating Table {i+1}...")
        await conn.execute_query(sql)
        
    print("Tables Created Successfully!")

if __name__ == "__main__":
    asyncio.run(init())
