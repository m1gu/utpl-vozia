# Prueba de flujos UTPL con datos sinteticos

## Archivos creados

| Archivo | Descripcion |
|---------|-------------|
| `pruebas/leads_prueba_100.csv` | 100 leads sinteticos (referencia, formato CSV) |
| `pruebas/leads_prueba.sql` | SQL INSERTs para cargar los 100 leads en Supabase |
| `flujo_n8n/UTPL_SIMULADOR.json` | Flujo n8n que simula llamadas Vapi (webhook `/utpl-simulador`) |
| `scripts/cargar_datos_prueba.js` | Script que genera el SQL con los 100 leads |
| `scripts/generar_csv_prueba.js` | Script para regenerar el CSV de referencia |
| `sql/utpl_registros_add_id_interno_negocio.sql` | SQL para la columna `id_interno_negocio` |
| `sql/utpl_crm_ddl.sql` | SQL para la tabla `utpl_crm` (auditoria de envios SOAP) |

## Distribucion de los 100 leads

| Escenario | Cantidad | Descripcion |
|-----------|----------|-------------|
| Fresh (PENDIENTE, intentos=0) | 35 | Listos para primera llamada |
| Sin telefonos | 5 | Se finalizan sin llamar |
| Mid-cycle (intentos 2-12) | 30 | En proceso de reintentos |
| Window limit (win_tries=3) | 15 | Cambio de ventana |
| Near max (intentos 14-15) | 15 | A punto de agotarse |
| Max intentos (16 = AGOTADO) | 5 | Activan CRM por agotamiento |
| Fecha reagenda futura | 10 | No listos para llamar aun |
| Sin id_interno_negocio | 19 | Prueban el campo opcional dealid |

## Distribucion de nomenclaturas del simulador

El simulador asigna la nomenclatura por hash del `id_negocio`:

| Nomenclatura | % | Accion |
|-------------|---|--------|
| ACE | 15% | FINALIZADO (sin CRM) |
| IND | 10% | FINALIZADO (sin CRM) |
| NUE | 10% | FINALIZADO (sin CRM) |
| VLL | 20% | REINTENTAR (sin CRM) |
| NC | 20% | REINTENTAR (sin CRM) |
| NIN | 25% | **FINALIZADO + CRM** (22 sub-motivos variados) |

---

## Paso 1: Ejecutar SQL de migraciones

En Supabase SQL Editor ejecutar en orden:
```sql
-- 1. Columna para el dealid del SOAP
ALTER TABLE public.utpl_registros ADD COLUMN IF NOT EXISTS id_interno_negocio TEXT;

-- 2. Tabla de auditoria de envios al CRM
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
```

---

## Paso 2: Cargar los 100 leads en Supabase

En Supabase SQL Editor:
1. Abrir el archivo `pruebas/leads_prueba.sql`
2. Copiar TODO el contenido
3. Pegar y ejecutar en el SQL Editor de Supabase

El SQL:
- Limpia datos de prueba anteriores (`LIKE 'SIM-%'`)
- Inserta 100 registros con todos los campos operativos
- Usa `ON CONFLICT (id_negocio) DO UPDATE` para preservar campos existentes

Si necesitas regenerar el SQL:
```bash
node scripts/cargar_datos_prueba.js
```

---

## Paso 3: Importar y activar el flujo simulador en n8n

1. Ir a `n8nps.plusservices.ec`
2. Importar `flujo_n8n/UTPL_SIMULADOR.json`
3. Activar el workflow (toggle a ON)
4. Verificar que el webhook esta activo en `https://n8nps.plusservices.ec/webhook/utpl-simulador`

---

## Paso 4: Configurar TEST MODE en Utpl_Llamadas

En `Utpl_Llamadas.json`, nodo `CONFIG INICIAL UTPL`, cambiar:
```js
runtime: { testMode: true, timeOffsetMinutes: 0 }
```

Esto redirige las "llamadas" al simulador en vez de Vapi.

---

## Paso 5: Activar los flujos y observar

1. Asegurar que el flujo `Utpl_CierreLlamadas` este activo
2. Activar el flujo `Utpl_Llamadas` (toggle ON)
3. El flujo procesara 1 lead cada 20 segundos
4. El simulador respondera con nomenclaturas variadas
5. Los leads con NIN activaran el envio SOAP al CRM
6. Los leads agotados (intentos=16) tambien activaran CRM

---

## Paso 6: Verificar resultados

### En Supabase
```sql
-- Ver nomenclaturas asignadas
SELECT id_nomenclatura, id_motivo, resumen_llamada, estado_flujo
FROM utpl_llamadas WHERE id_llamada LIKE 'sim-%'
ORDER BY fecha_gestion DESC;

-- Ver leads agotados con CRM
SELECT id_negocio, intentos_llamada, estado_flujo
FROM utpl_registros WHERE intentos_llamada >= 16;

-- Ver distribucion de nomenclaturas
SELECT id_nomenclatura, COUNT(*) as total
FROM utpl_llamadas WHERE id_llamada LIKE 'sim-%'
GROUP BY id_nomenclatura ORDER BY total DESC;

-- Ver envios al CRM (tabla de auditoria)
SELECT id_negocio, flujo_origen, nomenclatura, sales_stage_detail,
       http_code, id_return, error_messages, created_at
FROM utpl_crm ORDER BY created_at DESC;

-- Contar envios CRM por flujo de origen
SELECT flujo_origen, COUNT(*) as envios,
       COUNT(CASE WHEN http_code = '201' THEN 1 END) as exitosos,
       COUNT(CASE WHEN http_code != '201' THEN 1 END) as errores
FROM utpl_crm GROUP BY flujo_origen;
```

### En n8n Executions
- Revisar las ejecuciones de `Utpl_CierreLlamadas` para ver los XML SOAP generados
- En el nodo `PROCESA RESPUESTA CRM UTPL` verificar `httpCode` (debe ser 201 o error)
- Los errores del CRM no interrumpen el flujo

### Logs esperados por escenario

| Escenario | Flujo | Resultado esperado |
|-----------|-------|--------------------|
| Lead fresh con telefono | Llamadas | `GUARDA PRE-LLAMADA` → simulador → `CierreLlamadas` |
| Lead sin telefonos | Llamadas | `SIN NUMERO VALIDO` → `GUARDA REPORTE` (FINALIZADO) |
| Lead con intentos=16 | Llamadas | `SI FINAL AGOTADO` → `PREPARA SOAP XML AGOTADO` → CRM |
| Lead con NIN del simulador | CierreLlamadas | `CONDICION ENVIO CRM` → `MAPEA MOTIVO` → `PREPARA SOAP XML` → CRM |
| Lead con ACE/IND/NUE | CierreLlamadas | FINALIZADO sin CRM (sin pasar por CONDICION ENVIO) |
| Lead con NC/VLL | CierreLlamadas | REINTENTAR (sin CRM, se reintenta) |

---

## Paso 7: Restaurar a modo produccion

Al terminar las pruebas:
1. Apagar los flujos `Utpl_Llamadas` y `Utpl_CierreLlamadas`
2. Cambiar `testMode` a `false` en `CONFIG INICIAL UTPL`
3. Opcional: limpiar datos de prueba en Supabase:
```sql
DELETE FROM utpl_llamadas WHERE id_llamada LIKE 'sim-%';
DELETE FROM utpl_registros WHERE id_negocio LIKE 'SIM-%';
```
