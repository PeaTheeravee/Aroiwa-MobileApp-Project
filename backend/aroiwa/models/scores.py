from pydantic import BaseModel, ConfigDict
from sqlmodel import SQLModel, Field, Relationship

from . import users
from . import recipes


class BaseScore(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    score: int
    recipe_id: int
    user_id: int


class AvgScore(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    avg_score: float
    count: int


class CreatedScore(BaseScore):
    pass


class UpdatedScore(BaseScore):
    pass


class Score(BaseScore):
    id: int


class DBScore(BaseScore, SQLModel, table=True):
    __tablename__ = "scores"

    id: int = Field(default=None, primary_key=True)

    user_id: int = Field(default=None, foreign_key="users.id")
    user: users.DBUser | None = Relationship()

    recipe_id: int = Field(default=None, foreign_key="recipes.id")
    recipe: recipes.DBRecipe | None = Relationship()


class ScoreList(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    scores: list[Score]