from tortoise import Tortoise, run_async
from app.core.config import settings

async def upgrade():
    await Tortoise.init(
        db_url=settings.DATABASE_URL,
        modules={"models": []}
    )
    conn = Tortoise.get_connection("default")
    try:
        await conn.execute_script("ALTER TABLE trips ADD COLUMN status VARCHAR(50) DEFAULT 'SCHEDULED';")
        print("Schema Fixed: Added status column to trips.")
    except Exception as e:
        print(f"Schema Fix Failed (maybe column exists?): {e}")
    
    await Tortoise.close_connections()

if __name__ == "__main__":
    run_async(upgrade())
