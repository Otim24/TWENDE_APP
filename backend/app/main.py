import sentry_sdk                                    # 1. Add this import
from fastapi import FastAPI
from app.core.config import settings
from app.core.database import init_db

# 2. Add this initialization block exactly as Sentry generated it for you
sentry_sdk.init(
    dsn="https://909391b95c477df61a04692f66b5a84c@o4511531098832896.ingest.us.sentry.io/4511531291770880",
    # Add data like request headers and IP for users
    send_default_pii=True,
    # Captures performance data
    traces_sample_rate=1.0,
)

app = FastAPI(title=settings.PROJECT_NAME)

# 3. Add this temporary verification route right here
@app.get("/sentry-debug")
async def trigger_error():
    division_by_zero = 1 / 0

@app.get("/health")
async def health_check():
    return {"status": "ok", "service": "TWENDE API"}

# Initialize DB
init_db(app)

from app.api.v1 import auth, bookings, wallet, users, conductor

app.include_router(auth.router, prefix="/api/v1/auth", tags=["auth"])
app.include_router(bookings.router, prefix="/api/v1/bookings", tags=["bookings"])
app.include_router(wallet.router, prefix="/api/v1/wallet", tags=["wallet"])
app.include_router(users.router, prefix="/api/v1/users", tags=["users"])
app.include_router(conductor.router, prefix="/api/v1/conductor", tags=["conductor"])

from app.api.v1 import tracking
app.include_router(tracking.router, prefix="/api/v1/tracking", tags=["tracking"])


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)