-- utpl_registros: Agregar columna id_interno_negocio
-- Necesaria para enviar el dealid al CRM de UTPL (SOAP RegistrarLLamada)
-- ALTIVA debe enviar este campo en el webhook de entrada de datos

ALTER TABLE public.utpl_registros
ADD COLUMN IF NOT EXISTS id_interno_negocio TEXT;

COMMENT ON COLUMN public.utpl_registros.id_interno_negocio IS 'ID interno del negocio en ALTIVA/CRM. Usado como dealid en el envio SOAP a CRM UTPL.';
