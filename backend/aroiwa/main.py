from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from . import models
from . import routers
from . import config

def create_app():
    settings = config.get_settings()
    app = FastAPI()

    app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

    models.init_db(settings)
    routers.init_router(app)

    @app.on_event("startup")
    async def on_startup():
        await models.create_all()

    return app
