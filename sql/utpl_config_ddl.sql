-- utpl_config: Tabla de configuracion clave-valor
-- Almacena tokens, credenciales y parametros globales del sistema

CREATE TABLE IF NOT EXISTS public.utpl_config (
  key TEXT PRIMARY KEY,
  value TEXT,
  expires_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Valores iniciales (credenciales Altiva)
INSERT INTO public.utpl_config (key, value) VALUES ('client_id', '7')
ON CONFLICT (key) DO NOTHING;

INSERT INTO public.utpl_config (key, value) VALUES ('client_secret', 'ug7wMESTpOPPmdDC3KoEyYpVXskcOqRWnfHFZm8X')
ON CONFLICT (key) DO NOTHING;

INSERT INTO public.utpl_config (key, value) VALUES ('url_base', 'http://192.168.10.238:91')
ON CONFLICT (key) DO NOTHING;
