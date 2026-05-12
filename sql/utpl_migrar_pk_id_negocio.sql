-- ============================================================
-- UTPL - Migrar PK: cedula -> id_negocio
-- EJECUTAR EN ORDEN DENTRO DE UNA TRANSACCION
-- ============================================================
BEGIN;

-- 1. Agregar columna id_negocio si no existe
ALTER TABLE public.utpl_registros
ADD COLUMN IF NOT EXISTS id_negocio VARCHAR(100);

-- 2. Llenar id_negocio para registros existentes (usar cedula como fallback)
UPDATE public.utpl_registros
SET id_negocio = cedula
WHERE id_negocio IS NULL;

-- 3. Hacer id_negocio NOT NULL
ALTER TABLE public.utpl_registros ALTER COLUMN id_negocio SET NOT NULL;

-- 4. Eliminar FK en utpl_llamadas que depende del PK cedula
ALTER TABLE public.utpl_llamadas DROP CONSTRAINT IF EXISTS utpl_llamadas_cedula_fkey;

-- 5. Eliminar PK existente (cedula)
ALTER TABLE public.utpl_registros DROP CONSTRAINT IF EXISTS utpl_registros_pkey;

-- 6. Crear nueva PK sobre id_negocio
ALTER TABLE public.utpl_registros ADD PRIMARY KEY (id_negocio);

-- 7. Crear indice sobre cedula (sigue siendo campo de busqueda frecuente)
CREATE INDEX IF NOT EXISTS idx_utpl_registros_cedula ON public.utpl_registros (cedula);

COMMIT;
