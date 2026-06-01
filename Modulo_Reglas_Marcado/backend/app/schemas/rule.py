from uuid import UUID

from pydantic import BaseModel


class MotiveRuleBase(BaseModel):
    motive: str
    description: str | None = None
    action: str = "retry"
    phone_strategy: str = "same_number"
    wait_minutes: int = 5
    max_retries: int = 3
    sort_order: int = 0
    active: bool = True


class MotiveRuleCreate(MotiveRuleBase):
    pass


class MotiveRuleUpdate(BaseModel):
    motive: str | None = None
    description: str | None = None
    action: str | None = None
    phone_strategy: str | None = None
    wait_minutes: int | None = None
    max_retries: int | None = None
    sort_order: int | None = None
    active: bool | None = None


class MotiveRuleRead(MotiveRuleBase):
    id: UUID
    campaign_id: UUID

    model_config = {"from_attributes": True}
