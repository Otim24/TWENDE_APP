
from tortoise import Tortoise
from app.core.config import settings

TORTOISE_ORM = {
    "connections": {"default": settings.DATABASE_URL},
    "apps": {
        "models": {
            "models": [
                "app.models.user_model",
                "app.models.wallet_model",
                "app.models.bus_model",
                "app.models.trip_model",
                "app.models.booking_model",
                "app.models.cargo_model",
                "aerich.models"
            ],
            "default_connection": "default",
        },
    },
}

def init_db(app):
    from tortoise.contrib.fastapi import register_tortoise
    
    register_tortoise(
        app,
        config=TORTOISE_ORM,
        generate_schemas=True,
        add_exception_handlers=True,
    )
