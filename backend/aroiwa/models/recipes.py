from typing import List, Optional
from pydantic import BaseModel, ConfigDict
from sqlmodel import SQLModel, Field, Relationship

from . import users


class BaseRecipe(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    name: str
    imglink: str
    ingredients: Optional[str] = None
    method: Optional[str] = None

    user_id: int | None = 1


class CreatedRecipe(BaseRecipe):
    pass


class UpdatedRecipe(BaseRecipe):
    pass


class Recipe(BaseRecipe):
    id: int


class DBRecipe(BaseRecipe, SQLModel, table=True):
    __tablename__ = "recipes"

    id: int = Field(default=None, primary_key=True)

    user_id: int = Field(default=None, foreign_key="users.id")
    user: users.DBUser | None = Relationship()


class RecipeList(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    recipes: list[Recipe]
    page: int
    page_count: int
    size_per_page: int