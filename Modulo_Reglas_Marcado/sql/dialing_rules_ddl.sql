-- ============================================================================
-- Módulo de Reglas de Marcado: Tablas nuevas en Supabase
-- Proyecto: UTPL VozIA
-- Fecha: 2026-05-20
-- ============================================================================

BEGIN;

-- ═══════════════════════════════════════════════════════════════════════════
-- Tabla: dialing_campaigns
-- Una campaña por cada cliente o línea de negocio
-- ═══════════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS dialing_campaigns (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name                TEXT NOT NULL,
  slug                TEXT UNIQUE NOT NULL,
  description         TEXT,
  tz                  TEXT NOT NULL DEFAULT 'America/Guayaquil',
  cc                  TEXT NOT NULL DEFAULT '+593',
  max_lifetime_tries  INT NOT NULL DEFAULT 16,
  max_window_tries    INT NOT NULL DEFAULT 3,
  off_hours_wait_min  INT NOT NULL DEFAULT 30,
  active              BOOLEAN NOT NULL DEFAULT true,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ═══════════════════════════════════════════════════════════════════════════
-- Tabla: dialing_windows
-- Ventanas de marcado por campaña: días + horas
-- ═══════════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS dialing_windows (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_id   UUID NOT NULL REFERENCES dialing_campaigns(id) ON DELETE CASCADE,
  name          TEXT NOT NULL,
  days_csv      TEXT NOT NULL,              -- "1,2,3,4,5" = Lun-Vie, "6" = Sab, "7" = Dom
  start_time    TIME NOT NULL,              -- 08:00:00
  end_time      TIME NOT NULL,              -- 12:00:00
  sort_order    INT NOT NULL DEFAULT 0,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ═══════════════════════════════════════════════════════════════════════════
-- Tabla: dialing_holidays
-- Feriados por campaña
-- ═══════════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS dialing_holidays (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_id   UUID NOT NULL REFERENCES dialing_campaigns(id) ON DELETE CASCADE,
  holiday_date  DATE NOT NULL,
  description   TEXT,
  UNIQUE(campaign_id, holiday_date)
);

-- ═══════════════════════════════════════════════════════════════════════════
-- Tabla: dialing_motive_rules
-- Corazón del sistema: reglas por motivo
-- ═══════════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS dialing_motive_rules (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_id     UUID NOT NULL REFERENCES dialing_campaigns(id) ON DELETE CASCADE,
  motive          TEXT NOT NULL,            -- busy, voicemail, no_answer, failed, nom_NC, etc.
  description     TEXT,
  action          TEXT NOT NULL
    CHECK (action IN ('retry','finalize','escalate','next_window','next_day')),
  phone_strategy  TEXT NOT NULL DEFAULT 'same_number'
    CHECK (phone_strategy IN ('same_number','next_number','same_index','next_index')),
  wait_minutes    INT NOT NULL DEFAULT 5,
  max_retries     INT NOT NULL DEFAULT 3,
  sort_order      INT NOT NULL DEFAULT 0,
  active          BOOLEAN NOT NULL DEFAULT true,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(campaign_id, motive)
);

-- ═══════════════════════════════════════════════════════════════════════════
-- Tabla: dialing_attempts_log
-- Auditoría de evaluaciones del motor
-- ═══════════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS dialing_attempts_log (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_id     UUID NOT NULL REFERENCES dialing_campaigns(id),
  id_negocio      TEXT NOT NULL,
  cedula          TEXT NOT NULL,
  motive          TEXT NOT NULL,
  phone_used      TEXT NOT NULL,
  phone_index     INT NOT NULL,
  action_taken    TEXT NOT NULL,
  next_schedule   TIMESTAMPTZ,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ═══════════════════════════════════════════════════════════════════════════
-- Índices
-- ═══════════════════════════════════════════════════════════════════════════
CREATE INDEX IF NOT EXISTS idx_windows_campaign ON dialing_windows(campaign_id, sort_order);
CREATE INDEX IF NOT EXISTS idx_rules_campaign   ON dialing_motive_rules(campaign_id, sort_order);
CREATE INDEX IF NOT EXISTS idx_holidays_campaign ON dialing_holidays(campaign_id, holiday_date);
CREATE INDEX IF NOT EXISTS idx_attempts_lead    ON dialing_attempts_log(id_negocio, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_attempts_campaign ON dialing_attempts_log(campaign_id);

COMMIT;
