from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException

from app.api.deps import verify_api_key
from app.db.client import delete, insert, select, select_one
from app.schemas.holiday import HolidayCreate, HolidayRead

router = APIRouter(
    prefix="/campaigns/{campaign_id}/holidays",
    tags=["holidays"],
    dependencies=[Depends(verify_api_key)],
)


@router.get("", response_model=list[HolidayRead])
async def list_holidays(campaign_id: UUID):
    rows = await select(
        "dialing_holidays",
        filters={"campaign_id": f"eq.{campaign_id}"},
        order="holiday_date.desc",
    )
    return [HolidayRead(**r) for r in rows]


@router.post("", response_model=HolidayRead, status_code=201)
async def create_holiday(campaign_id: UUID, body: HolidayCreate):
    campaign = await select_one("dialing_campaigns", {"id": f"eq.{campaign_id}"})
    if not campaign:
        raise HTTPException(status_code=404, detail="Campaign no encontrada")

    existing = await select_one(
        "dialing_holidays",
        {
            "campaign_id": f"eq.{campaign_id}",
            "holiday_date": f"eq.{body.holiday_date}",
        },
    )
    if existing:
        raise HTTPException(status_code=409, detail="Ya existe un feriado en esa fecha")

    data = body.model_dump()
    data["campaign_id"] = str(campaign_id)
    result = await insert("dialing_holidays", data)
    return HolidayRead(**result)


@router.delete("/{holiday_id}", status_code=204)
async def delete_holiday(campaign_id: UUID, holiday_id: UUID):
    row = await select_one(
        "dialing_holidays",
        {"id": f"eq.{holiday_id}", "campaign_id": f"eq.{campaign_id}"},
    )
    if not row:
        raise HTTPException(status_code=404, detail="Holiday no encontrado")
    await delete("dialing_holidays", {"id": f"eq.{holiday_id}"})
