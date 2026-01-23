from tortoise import Tortoise, run_async
from app.core.config import settings

async def upgrade():
    await Tortoise.init(
        db_url=settings.DATABASE_URL,
        modules={"models": []}
    )
    conn = Tortoise.get_connection("default")
    
    # List of columns to check/add
    columns = [
        ("arrival_time", "TIMESTAMP WITH TIME ZONE"),
        ("departure_time", "TIMESTAMP WITH TIME ZONE"),
        ("price", "DECIMAL(10, 2) DEFAULT 0.00"),
        ("route_id", "INTEGER"),
        ("bus_id", "INTEGER")
    ]

    for col_name, col_type in columns:
        try:
            await conn.execute_script(f"ALTER TABLE trips ADD COLUMN {col_name} {col_type};")
            print(f"Schema Fixed: Added {col_name} to trips.")
        except Exception as e:
            # Postgres error code for "duplicate column" is 42701, but we catch generic exception for simplicity
            print(f"Skipping {col_name} (likely exists or error): {e}")

    # Add default route if needed? No, let's keep it simple.
    
    await Tortoise.close_connections()

if __name__ == "__main__":
    run_async(upgrade())
