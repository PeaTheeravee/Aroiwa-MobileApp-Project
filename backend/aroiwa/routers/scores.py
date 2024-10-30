from typing import Annotated

from fastapi import APIRouter, HTTPException, Depends, Query

from sqlmodel import Session, select, func
from sqlmodel.ext.asyncio.session import AsyncSession

from aroiwa.models import *
from aroiwa.models.scores import *

from aroiwa.models.users import *

from aroiwa.deps import *

import math


router = APIRouter(prefix="/scores", tags=["scores"])


@router.post("/create")
async def create_score(
    score: CreatedScore,
    session: Annotated[AsyncSession, Depends(get_session)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> Score | None:

    data = score.dict()
    db_score = DBScore(**data)

    session.add(db_score)
    await session.commit()
    await session.refresh(db_score)

    return Score.from_orm(db_score)


@router.get("/{recipe_id}")
async def read_score(
    recipe_id: int,
    session: Annotated[AsyncSession, Depends(get_session)],
) -> AvgScore:

    # Query ค่าเฉลี่ยและจำนวนคะแนน
    score_query = await session.exec(
        select(func.avg(DBScore.score), func.count(DBScore.score))
        .filter(DBScore.recipe_id == recipe_id)
    )

    avg_score, score_count = score_query.first()
    avg_score_rounded = round(float(avg_score) if avg_score is not None else 0.0, 1)

    return AvgScore(avg_score=avg_score_rounded, count=score_count)


@router.get("/personal/{user_id}/{recipe_id}")
async def personal_score(
    recipe_id: int,
    user_id: int,
    session: Annotated[AsyncSession, Depends(get_session)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> Score:
    # ตรวจสอบว่ามีคะแนนที่ตรงกับ recipe_id และ user_id หรือไม่
    score_query = await session.exec(
        select(DBScore).filter(DBScore.recipe_id == recipe_id, DBScore.user_id == user_id)
    )

    db_score = score_query.first()
    
    if db_score is None:
        raise HTTPException(status_code=404, detail="Score not found")
    
    return Score.from_orm(db_score)



@router.get("/canpost/{user_id}/{recipe_id}")
async def canpost_score(
    recipe_id: int,
    user_id: int,
    session: Annotated[AsyncSession, Depends(get_session)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> bool:
    # ตรวจสอบว่ามีคะแนนที่ตรงกับ recipe_id และ user_id หรือไม่
    score_query = await session.exec(
        select(DBScore).filter(DBScore.recipe_id == recipe_id, DBScore.user_id == user_id)
    )

    score_exists = score_query.first() is not None

    # คืนค่า True เมื่อไม่พบ และ False เมื่อพบ
    return not score_exists


@router.put("/updatescore/{user_id}/{recipe_id}/{new_score}")
async def update_score(
    user_id: int,
    recipe_id: int,
    new_score: int,
    session: Annotated[AsyncSession, Depends(get_session)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> Score:
    # ค้นหาคะแนนที่ตรงกับ user_id และ recipe_id
    score_query = await session.exec(
        select(DBScore).filter(DBScore.user_id == user_id, DBScore.recipe_id == recipe_id)
    )

    db_score = score_query.first()
    if db_score is None:
        raise HTTPException(status_code=404, detail="Score not found")

    # อัปเดตคะแนน
    db_score.score = new_score

    # บันทึกการเปลี่ยนแปลงในฐานข้อมูล
    session.add(db_score)
    await session.commit()
    await session.refresh(db_score)

    return Score.from_orm(db_score)
