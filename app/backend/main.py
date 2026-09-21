from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

# Routers
from stt.ws_stt import router as stt_router
from vision.yolo_routes import router as vision_router

# ==========================================================
# FASTAPI APP
# ==========================================================
app = FastAPI()

print("🚀 STT Backend starting...")

# ==========================================================
# CORS
# ==========================================================
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ==========================================================
# ROUTERS
# ==========================================================
app.include_router(stt_router)
app.include_router(vision_router)

# ==========================================================
# HEALTH CHECK (utile per debug)
# ==========================================================
@app.get("/health")
async def health():
    return {"status": "ok"}
