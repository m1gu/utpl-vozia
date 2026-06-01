from pydantic import BaseModel


class LeadData(BaseModel):
    id_negocio: str
    cedula: str
    intentos_llamada: int = 0
    telefono_index: int = 0
    win_tries: int = 0
    win_stamp: str | None = None
    estado_flujo: str = "PENDIENTE"
    fecha_reagenda: str | None = None
    phones: list[str] = []
    motive_counters: dict[str, int] = {}


class EvaluateRequest(BaseModel):
    campaign_slug: str
    lead: LeadData


class EvaluateResponse(BaseModel):
    can_call: bool
    phone_to_call: str | None = None
    phone_index: int = 0
    win_tries: int = 0
    win_stamp: str | None = None
    estado_flujo: str = "PENDIENTE"
    next_schedule: str | None = None
    motivo: str = ""
    reason: str = ""


class ClassifyRequest(BaseModel):
    campaign_slug: str
    lead: LeadData
    nomenclatura: str | None = None
    ended_reason: str | None = None
    phone_used: str | None = None


class ClassifyResponse(BaseModel):
    estado_flujo: str = "FINALIZADO"
    status_sugerido: str = "FINAL"
    phone_index: int = 0
    next_schedule: str | None = None
    wait_minutes: int = 0
    motive: str = ""
    action: str = ""
    phone_strategy: str = ""
    motive_counters: dict[str, int] = {}
