
from tortoise import Tortoise
from app.core.config import settings

def init_db(app):
    from tortoise.contrib.fastapi import register_tortoise
    
    register_tortoise(
        app,
        db_url=settings.DATABASE_URL,
        modules={"models": ["app.models.user_model", "app.models.wallet_model", "app.models.bus_model", "app.models.trip_model", "app.models.booking_model", "app.models.cargo_model"]},
        generate_schemas=True,
        add_exception_handlers=True,
    )
