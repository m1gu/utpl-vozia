from uuid import UUID

from pydantic import BaseModel


class HolidayCreate(BaseModel):
    holiday_date: str
    description: str | None = None


class HolidayRead(HolidayCreate):
    id: UUID
    campaign_id: UUID

    model_config = {"from_attributes": True}
