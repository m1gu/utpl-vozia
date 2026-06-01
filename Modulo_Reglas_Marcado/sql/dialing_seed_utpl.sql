-- ============================================================================
-- Seed data: Campaña UTPL VozIA + Ventanas + Feriados + Reglas por motivo
-- Ejecutar DESPUÉS de dialing_rules_ddl.sql
-- ============================================================================

BEGIN;

-- 1. Insertar campaña UTPL
INSERT INTO dialing_campaigns (name, slug, description, tz, cc, max_lifetime_tries, max_window_tries, off_hours_wait_min)
VALUES (
  'UTPL Captacion',
  'utpl-vozia',
  'Campaña de llamadas para captación de estudiantes UTPL',
  'America/Guayaquil',
  '+593',
  16,
  3,
  30
);

-- 2. Insertar ventanas de marcado (MAÑANA, TARDE, NOCHE)
INSERT INTO dialing_windows (campaign_id, name, days_csv, start_time, end_time, sort_order)
SELECT id, 'MAÑANA', '1,2,3,4,5', '08:00'::time, '12:00'::time, 1
FROM dialing_campaigns WHERE slug = 'utpl-vozia'
UNION ALL
SELECT id, 'TARDE', '1,2,3,4,5', '12:01'::time, '14:00'::time, 2
FROM dialing_campaigns WHERE slug = 'utpl-vozia'
UNION ALL
SELECT id, 'NOCHE', '1,2,3,4,5', '14:01'::time, '20:00'::time, 3
FROM dialing_campaigns WHERE slug = 'utpl-vozia';

-- 3. Insertar feriado: Lunes 25 de Mayo 2026
INSERT INTO dialing_holidays (campaign_id, holiday_date, description)
SELECT id, '2026-05-25'::date, 'Feriado (configurado en flujo original)'
FROM dialing_campaigns WHERE slug = 'utpl-vozia';

-- 4. Insertar reglas por motivo para UTPL
INSERT INTO dialing_motive_rules (campaign_id, motive, description, action, phone_strategy, wait_minutes, max_retries, sort_order)
SELECT id, 'nom_NC',       'No Contacto (nomenclatura)',         'retry',      'next_number',  0,   99,  1
FROM dialing_campaigns WHERE slug = 'utpl-vozia'
UNION ALL
SELECT id, 'nom_VLL',      'Volver a Llamar (nomenclatura)',     'retry',      'same_number',  30,  99,  2
FROM dialing_campaigns WHERE slug = 'utpl-vozia'
UNION ALL
SELECT id, 'busy',         'Suena ocupado',                       'retry',      'same_number',  5,   3,   3
FROM dialing_campaigns WHERE slug = 'utpl-vozia'
UNION ALL
SELECT id, 'voicemail',    'Buzón de voz',                        'retry',      'next_number',  15,  2,   4
FROM dialing_campaigns WHERE slug = 'utpl-vozia'
UNION ALL
SELECT id, 'no_answer',    'No contesta',                         'retry',      'same_number',  30,  5,   5
FROM dialing_campaigns WHERE slug = 'utpl-vozia'
UNION ALL
SELECT id, 'failed',       'Fallo técnico',                       'retry',      'same_number',  10,  3,   6
FROM dialing_campaigns WHERE slug = 'utpl-vozia';

COMMIT;

-- Verificación
SELECT 'Campaigns' AS tbl, count(*) AS rows FROM dialing_campaigns
UNION ALL
SELECT 'Windows', count(*) FROM dialing_windows
UNION ALL
SELECT 'Holidays', count(*) FROM dialing_holidays
UNION ALL
SELECT 'MotiveRules', count(*) FROM dialing_motive_rules;
