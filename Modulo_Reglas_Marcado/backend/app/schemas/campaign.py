from uuid import UUID

from pydantic import BaseModel, Field


class CampaignBase(BaseModel):
    name: str
    slug: str
    description: str | None = None
    tz: str = "America/Guayaquil"
    cc: str = "+593"
    max_lifetime_tries: int = 16
    max_window_tries: int = 3
    off_hours_wait_min: int = 30
    active: bool = True


class CampaignCreate(CampaignBase):
    pass


class CampaignUpdate(BaseModel):
    name: str | None = None
    description: str | None = None
    tz: str | None = None
    cc: str | None = None
    max_lifetime_tries: int | None = None
    max_window_tries: int | None = None
    off_hours_wait_min: int | None = None
    active: bool | None = None


class CampaignRead(CampaignBase):
    id: UUID
    created_at: str | None = None
    updated_at: str | None = None

    model_config = {"from_attributes": True}
