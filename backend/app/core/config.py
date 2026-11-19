from typing import Optional
from pydantic import Field
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    PROJECT_NAME: str = "Twende API"
    DATABASE_URL: str = Field(repr=False, exclude=True)
    REDIS_URL: str
    SECRET_KEY: str = Field(repr=False, exclude=True)
    API_V1_STR: str = "/api/v1"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 1440
    SENTRY_DSN: Optional[str] = Field(default=None, repr=False, exclude=True)
    BACKEND_CORS_ORIGINS: list[str] = ["*"]

    class Config:
        env_file = ".env"


settings = Settings()
