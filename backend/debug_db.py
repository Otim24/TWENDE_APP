import asyncio
from tortoise import Tortoise
from app.core.config import settings

async def init():
    print("Attempting to connect to DB at:", settings.DATABASE_URL)
    try:
        await Tortoise.init(
            db_url=settings.DATABASE_URL,
            modules={"models": ["app.models.user_model", "app.models.wallet_model", "app.models.bus_model", "app.models.booking_model", "app.models.cargo_model", "app.models.trip_model"]},
        )
        print("Connection successful!")
        print("Generating Schemas...")
        await Tortoise.generate_schemas()
        print("Schemas generated successfully!")
    except Exception as e:
        print("ERROR OCCURRED:")
        print(e)
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    asyncio.run(init())
