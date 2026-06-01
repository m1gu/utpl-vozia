-- ============================================================================
-- Agrega 2 campos a utpl_registros para el nuevo motor de reglas de marcado
-- ============================================================================

-- 1. Vincula el lead a una campaña del motor dialing-rules-engine
ALTER TABLE utpl_registros
ADD COLUMN campaign_slug VARCHAR(50) DEFAULT 'utpl-vozia';

-- 2. Contadores de intentos por motivo en JSONB
--    Ejemplo: {"busy": 2, "voicemail": 1, "no_answer": 3, "nom_NC": 0, "nom_VLL": 1}
ALTER TABLE utpl_registros
ADD COLUMN motive_counters JSONB DEFAULT '{}'::jsonb;

-- Actualizar registros existentes para que tengan el slug por defecto
UPDATE utpl_registros SET campaign_slug = 'utpl-vozia' WHERE campaign_slug IS NULL;
