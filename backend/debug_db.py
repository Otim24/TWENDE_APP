import asyncio
from urllib.parse import urlparse
from tortoise import Tortoise
from app.core.config import settings


def _redacted_db_url(url: str) -> str:
    parsed = urlparse(url)
    if parsed.password:
        netloc = f"{parsed.username}:***@{parsed.hostname}"
        if parsed.port:
            netloc += f":{parsed.port}"
        return parsed._replace(netloc=netloc).geturl()
    return url


async def init():
    print("Attempting to connect to DB at:", _redacted_db_url(settings.DATABASE_URL))
    try:
        await Tortoise.init(
            db_url=settings.DATABASE_URL,
            modules={
                "models": [
                    "app.models.user_model",
                    "app.models.wallet_model",
                    "app.models.bus_model",
                    "app.models.booking_model",
                    "app.models.trip_model",
                ]
            },
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
