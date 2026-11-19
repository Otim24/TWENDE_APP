import sentry_sdk
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings
from app.core.database import init_db

if settings.SENTRY_DSN:
    sentry_sdk.init(
        dsn=settings.SENTRY_DSN,
        send_default_pii=False,
        traces_sample_rate=1.0,
    )

app = FastAPI(title=settings.PROJECT_NAME)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.BACKEND_CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
async def health_check():
    return {"status": "ok", "service": "TWENDE API"}


# Initialize DB
init_db(app)

from app.api.v1 import auth, bookings, wallet, users, conductor, tracking

app.include_router(auth.router, prefix="/api/v1/auth", tags=["auth"])
app.include_router(bookings.router, prefix="/api/v1/bookings", tags=["bookings"])
app.include_router(wallet.router, prefix="/api/v1/wallet", tags=["wallet"])
app.include_router(users.router, prefix="/api/v1/users", tags=["users"])
app.include_router(conductor.router, prefix="/api/v1/conductor", tags=["conductor"])
app.include_router(tracking.router, prefix="/api/v1/tracking", tags=["tracking"])


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)
