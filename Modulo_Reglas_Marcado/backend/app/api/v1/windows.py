from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException

from app.api.deps import verify_api_key
from app.db.client import delete, insert, select, select_one, update
from app.schemas.window import WindowCreate, WindowRead, WindowUpdate

router = APIRouter(
    prefix="/campaigns/{campaign_id}/windows",
    tags=["windows"],
    dependencies=[Depends(verify_api_key)],
)


@router.get("", response_model=list[WindowRead])
async def list_windows(campaign_id: UUID):
    rows = await select(
        "dialing_windows",
        filters={"campaign_id": f"eq.{campaign_id}"},
        order="sort_order.asc",
    )
    return [WindowRead(**r) for r in rows]


@router.get("/{window_id}", response_model=WindowRead)
async def get_window(campaign_id: UUID, window_id: UUID):
    row = await select_one(
        "dialing_windows",
        {"id": f"eq.{window_id}", "campaign_id": f"eq.{campaign_id}"},
    )
    if not row:
        raise HTTPException(status_code=404, detail="Window no encontrada")
    return WindowRead(**row)


@router.post("", response_model=WindowRead, status_code=201)
async def create_window(campaign_id: UUID, body: WindowCreate):
    campaign = await select_one("dialing_campaigns", {"id": f"eq.{campaign_id}"})
    if not campaign:
        raise HTTPException(status_code=404, detail="Campaign no encontrada")

    data = body.model_dump()
    data["campaign_id"] = str(campaign_id)
    result = await insert("dialing_windows", data)
    return WindowRead(**result)


@router.put("/{window_id}", response_model=WindowRead)
async def update_window(campaign_id: UUID, window_id: UUID, body: WindowUpdate):
    row = await select_one(
        "dialing_windows",
        {"id": f"eq.{window_id}", "campaign_id": f"eq.{campaign_id}"},
    )
    if not row:
        raise HTTPException(status_code=404, detail="Window no encontrada")

    data = body.model_dump(exclude_none=True)
    result = await update("dialing_windows", {"id": f"eq.{window_id}"}, data)
    return WindowRead(**result)


@router.delete("/{window_id}", status_code=204)
async def delete_window(campaign_id: UUID, window_id: UUID):
    row = await select_one(
        "dialing_windows",
        {"id": f"eq.{window_id}", "campaign_id": f"eq.{campaign_id}"},
    )
    if not row:
        raise HTTPException(status_code=404, detail="Window no encontrada")
    await delete("dialing_windows", {"id": f"eq.{window_id}"})
