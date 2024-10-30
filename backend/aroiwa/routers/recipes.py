from typing import Annotated

from sqlalchemy import delete
from sqlalchemy.exc import IntegrityError

from fastapi import APIRouter, HTTPException, Depends, Query

from sqlmodel import Session, select, func
from sqlmodel.ext.asyncio.session import AsyncSession

from aroiwa.models import *
from aroiwa.models.recipes import *

from aroiwa.models.users import *

from aroiwa.models.scores import *

from aroiwa.deps import *

import math


router = APIRouter(prefix="/recipes", tags=["recipes"])

SIZE_PER_PAGE = 50


@router.post("/create")
async def create_recipe(
    recipe: CreatedRecipe,
    session: Annotated[AsyncSession, Depends(get_session)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> Recipe | None:

    data = recipe.dict()

    dbrecipe = DBRecipe(**data)
    session.add(dbrecipe)
    await session.commit()
    await session.refresh(dbrecipe)

    return Recipe.from_orm(dbrecipe)


@router.get("/all")
async def read_recipes(
    session: Annotated[AsyncSession, Depends(get_session)],
    page: int = 1,
) -> RecipeList:

    result = await session.exec(select(DBRecipe).offset((page - 1) * SIZE_PER_PAGE).limit(SIZE_PER_PAGE))
    recipes = result.all()
        
    page_count = int(
        math.ceil(
            (await session.exec(select(func.count(DBRecipe.id)))).first()
            / SIZE_PER_PAGE
        )
    )

    print("page_count", page_count)
    print("recipes", recipes)

    return RecipeList.from_orm(
        dict(recipes=recipes, page_count=page_count, page=page, size_per_page=SIZE_PER_PAGE)
    )


@router.get("/{recipe_id}")
async def read_recipe(
    recipe_id: int, session: Annotated[AsyncSession, Depends(get_session)]
) -> Recipe:

    db_recipe = await session.get(DBRecipe, recipe_id)
    if db_recipe:
        return Recipe.from_orm(db_recipe)

    raise HTTPException(status_code=404, detail="Item not found")


@router.put("/{recipe_id}/update")
async def update_recipe(
    recipe_id: int,
    recipe: UpdatedRecipe,
    session: Annotated[AsyncSession, Depends(get_session)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> Recipe:

    data = recipe.dict()

    db_recipe = await session.get(DBRecipe, recipe_id)
    db_recipe.sqlmodel_update(data)
    
    session.add(db_recipe)
    await session.commit()
    await session.refresh(db_recipe)

    return Recipe.from_orm(db_recipe)


@router.delete("/{recipe_id}/delete")
async def delete_recipe(
    recipe_id: int,
    session: Annotated[AsyncSession, Depends(get_session)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> dict:
    try:
        # ลบข้อมูลที่เกี่ยวข้องในตาราง scores ก่อน
        await session.execute(
            delete(DBScore).where(DBScore.recipe_id == recipe_id)  # ใช้ DBScore แทน Score
        )
        await session.commit()

        # ลบข้อมูลในตาราง recipes
        db_recipe = await session.get(DBRecipe, recipe_id)
        if db_recipe:
            await session.delete(db_recipe)
            await session.commit()

            return dict(message="delete success")
        else:
            return dict(message="recipe not found")

    except IntegrityError as e:
        await session.rollback()
        return dict(message=f"Failed to delete due to integrity error: {str(e)}")