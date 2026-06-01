-- Agregar columna nombre_corto_campania a utpl_registros
-- Se usa en la notificacion a Altiva (campo nombre_corto_campania del endpoint actualizar nodo)

ALTER TABLE public.utpl_registros ADD COLUMN IF NOT EXISTS nombre_corto_campania TEXT;

COMMENT ON COLUMN public.utpl_registros.nombre_corto_campania IS 'Nombre corto de la campania en Altiva. Se envia en la notificacion de actualizacion de nodo a la API de Altiva.';
