from . import recipes
from . import users
from . import authentication
from . import scores

def init_router(app):
    app.include_router(users.router)
    app.include_router(authentication.router)
    app.include_router(recipes.router)
    app.include_router(scores.router)