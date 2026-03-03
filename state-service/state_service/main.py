from fastapi import FastAPI

from .routes import router

app = FastAPI(title="AI Gateway State Service", version="0.1.0")
app.include_router(router)
