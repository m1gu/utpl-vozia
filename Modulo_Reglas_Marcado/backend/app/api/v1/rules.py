from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from app.api.deps import verify_api_key
from app.db.client import delete, insert, select, select_one, update
from app.schemas.rule import MotiveRuleCreate, MotiveRuleRead, MotiveRuleUpdate

router = APIRouter(
    prefix="/campaigns/{campaign_id}/rules",
    tags=["rules"],
    dependencies=[Depends(verify_api_key)],
)


@router.get("", response_model=list[MotiveRuleRead])
async def list_rules(campaign_id: UUID):
    rows = await select(
        "dialing_motive_rules",
        filters={"campaign_id": f"eq.{campaign_id}"},
        order="sort_order.asc",
    )
    return [MotiveRuleRead(**r) for r in rows]


@router.get("/{rule_id}", response_model=MotiveRuleRead)
async def get_rule(campaign_id: UUID, rule_id: UUID):
    row = await select_one(
        "dialing_motive_rules",
        {"id": f"eq.{rule_id}", "campaign_id": f"eq.{campaign_id}"},
    )
    if not row:
        raise HTTPException(status_code=404, detail="Rule no encontrada")
    return MotiveRuleRead(**row)


@router.post("", response_model=MotiveRuleRead, status_code=201)
async def create_rule(campaign_id: UUID, body: MotiveRuleCreate):
    campaign = await select_one("dialing_campaigns", {"id": f"eq.{campaign_id}"})
    if not campaign:
        raise HTTPException(status_code=404, detail="Campaign no encontrada")

    existing = await select_one(
        "dialing_motive_rules",
        {
            "campaign_id": f"eq.{campaign_id}",
            "motive": f"eq.{body.motive}",
        },
    )
    if existing:
        raise HTTPException(status_code=409, detail="Ya existe una regla con ese motivo")

    data = body.model_dump()
    data["campaign_id"] = str(campaign_id)
    result = await insert("dialing_motive_rules", data)
    return MotiveRuleRead(**result)


@router.put("/{rule_id}", response_model=MotiveRuleRead)
async def update_rule(campaign_id: UUID, rule_id: UUID, body: MotiveRuleUpdate):
    row = await select_one(
        "dialing_motive_rules",
        {"id": f"eq.{rule_id}", "campaign_id": f"eq.{campaign_id}"},
    )
    if not row:
        raise HTTPException(status_code=404, detail="Rule no encontrada")

    data = body.model_dump(exclude_none=True)
    if "motive" in data:
        existing = await select_one(
            "dialing_motive_rules",
            {
                "campaign_id": f"eq.{campaign_id}",
                "motive": f"eq.{data['motive']}",
            },
        )
        if existing and str(existing["id"]) != str(rule_id):
            raise HTTPException(status_code=409, detail="Ya existe una regla con ese motivo")

    result = await update("dialing_motive_rules", {"id": f"eq.{rule_id}"}, data)
    return MotiveRuleRead(**result)


@router.delete("/{rule_id}", status_code=204)
async def delete_rule(campaign_id: UUID, rule_id: UUID):
    row = await select_one(
        "dialing_motive_rules",
        {"id": f"eq.{rule_id}", "campaign_id": f"eq.{campaign_id}"},
    )
    if not row:
        raise HTTPException(status_code=404, detail="Rule no encontrada")
    await delete("dialing_motive_rules", {"id": f"eq.{rule_id}"})


class ReorderRequest(BaseModel):
    rule_ids: list[UUID]


@router.put("/reorder", response_model=list[MotiveRuleRead])
async def reorder_rules(campaign_id: UUID, body: ReorderRequest):
    for idx, rule_id in enumerate(body.rule_ids):
        await update(
            "dialing_motive_rules",
            {"id": f"eq.{rule_id}", "campaign_id": f"eq.{campaign_id}"},
            {"sort_order": idx},
        )

    rows = await select(
        "dialing_motive_rules",
        filters={"campaign_id": f"eq.{campaign_id}"},
        order="sort_order.asc",
    )
    return [MotiveRuleRead(**r) for r in rows]
