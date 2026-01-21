
from fastapi import FastAPI
from app.core.config import settings
from app.core.database import init_db

app = FastAPI(title=settings.PROJECT_NAME)

@app.get("/health")
async def health_check():
    return {"status": "ok", "service": "TWENDE API"}

# Initialize DB
init_db(app)

from app.api.v1 import auth
app.include_router(auth.router, prefix="/api/v1/auth", tags=["auth"])


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)
