from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query

from app.api.deps import verify_api_key
from app.db.client import delete, insert, select, select_one, update
from app.schemas.campaign import CampaignCreate, CampaignRead, CampaignUpdate

router = APIRouter(prefix="/campaigns", tags=["campaigns"], dependencies=[Depends(verify_api_key)])


@router.get("", response_model=list[CampaignRead])
async def list_campaigns():
    rows = await select("dialing_campaigns", order="name.asc")
    return [CampaignRead(**r) for r in rows]


@router.get("/{campaign_id}", response_model=CampaignRead)
async def get_campaign(campaign_id: UUID):
    row = await select_one("dialing_campaigns", {"id": f"eq.{campaign_id}"})
    if not row:
        raise HTTPException(status_code=404, detail="Campaign no encontrada")
    return CampaignRead(**row)


@router.post("", response_model=CampaignRead, status_code=201)
async def create_campaign(body: CampaignCreate):
    existing = await select_one("dialing_campaigns", {"slug": f"eq.{body.slug}"})
    if existing:
        raise HTTPException(status_code=409, detail="Ya existe una campana con ese slug")

    data = body.model_dump()
    result = await insert("dialing_campaigns", data)
    return CampaignRead(**result)


@router.put("/{campaign_id}", response_model=CampaignRead)
async def update_campaign(campaign_id: UUID, body: CampaignUpdate):
    row = await select_one("dialing_campaigns", {"id": f"eq.{campaign_id}"})
    if not row:
        raise HTTPException(status_code=404, detail="Campaign no encontrada")

    data = body.model_dump(exclude_none=True)
    result = await update("dialing_campaigns", {"id": f"eq.{campaign_id}"}, data)
    return CampaignRead(**result)


@router.delete("/{campaign_id}", status_code=204)
async def delete_campaign(campaign_id: UUID):
    row = await select_one("dialing_campaigns", {"id": f"eq.{campaign_id}"})
    if not row:
        raise HTTPException(status_code=404, detail="Campaign no encontrada")
    await delete("dialing_campaigns", {"id": f"eq.{campaign_id}"})
