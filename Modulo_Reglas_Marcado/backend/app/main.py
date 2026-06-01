from contextlib import asynccontextmanager

from fastapi import FastAPI

from app.api.v1.campaigns import router as campaigns_router
from app.api.v1.holidays import router as holidays_router
from app.api.v1.rules import router as rules_router
from app.api.v1.windows import router as windows_router
from app.db.client import select


@asynccontextmanager
async def lifespan(app: FastAPI):
    yield


app = FastAPI(
    title="Dialing Rules Engine",
    description="Motor de reglas de marcado multi-campaña",
    version="0.1.0",
    lifespan=lifespan,
)


@app.get("/health")
async def health():
    try:
        await select("dialing_campaigns", columns="id", limit=1)
        db_status = "connected"
    except Exception:
        db_status = "disconnected"

    return {
        "status": "ok",
        "db": db_status,
    }


app.include_router(campaigns_router, prefix="/api/v1")
app.include_router(windows_router, prefix="/api/v1")
app.include_router(holidays_router, prefix="/api/v1")
app.include_router(rules_router, prefix="/api/v1")


if __name__ == "__main__":
    import uvicorn

    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)
