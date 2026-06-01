from uuid import UUID

from pydantic import BaseModel


class WindowBase(BaseModel):
    name: str
    days_csv: str = "1,2,3,4,5"
    start_time: str = "08:00"
    end_time: str = "12:00"
    sort_order: int = 0


class WindowCreate(WindowBase):
    pass


class WindowUpdate(BaseModel):
    name: str | None = None
    days_csv: str | None = None
    start_time: str | None = None
    end_time: str | None = None
    sort_order: int | None = None


class WindowRead(WindowBase):
    id: UUID
    campaign_id: UUID

    model_config = {"from_attributes": True}
