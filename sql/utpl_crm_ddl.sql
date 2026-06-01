-- utpl_crm: Auditoria de envios SOAP al CRM de UTPL
-- Registra cada peticion enviada y su respuesta del web service RegistrarLLamada

CREATE TABLE IF NOT EXISTS public.utpl_crm (
  id                  BIGSERIAL PRIMARY KEY,
  id_negocio          TEXT NOT NULL,
  flujo_origen        TEXT NOT NULL,
  nomenclatura        TEXT,
  dealstage           TEXT,
  hs_call_disposition TEXT,
  sales_stage_detail  TEXT,
  agent_name          TEXT,
  hs_call_duration    TEXT,
  hs_call_body        TEXT,
  commitment_date     TEXT,
  dealid              TEXT,
  hs_timestamp        TEXT,
  scheduling_date     TEXT,
  soap_xml            TEXT,
  http_code           TEXT,
  id_return           TEXT,
  error_messages      TEXT,
  created_at          TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_utpl_crm_id_negocio ON public.utpl_crm(id_negocio);
CREATE INDEX IF NOT EXISTS idx_utpl_crm_created_at ON public.utpl_crm(created_at);
