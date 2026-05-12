# UTPL VozIA - Especificacion Tecnica (SPECS.md)

## 1. Arquitectura del Sistema

### 1.1 Diagrama de Integracion

```
┌──────────┐     ┌──────────────────┐     ┌──────────────┐
│  ALTIVA  │────►│  n8n (orquestador)│────►│   Supabase   │
│ (origen) │     │ n8nps.plusservices│     │ (base datos) │
└──────────┘     └────────┬─────────┘     └──────────────┘
                          │
                    ┌─────┴─────┐
                    │  Vapi AI  │
                    │ (llamadas)│
                    └───────────┘
```

### 1.2 Ciclo de Vida de un Registro

```
1. ALTIVA envia datos ──► ENTRADA_DATOS ──► INSERT/UPDATE utpl_registros (estado_flujo=PENDIENTE)
2. Schedule (60s) ──► BUSCA Y BLOQUEA ──► POLITICAS 3x3 ──► LLAMAR VAPI
3. Vapi finaliza llamada ──► webhook CIERRE ──► ACTUALIZA REGISTRO + INSERT utpl_llamadas
```

---

## 2. Tablas de Base de Datos

### 2.1 utpl_registros (Registro Maestro)

| Columna | Tipo | Descripcion |
|---------|------|-------------|
| `id_negocio` | VARCHAR(100) PK | Identificador unico del negocio/lead |
| `cedula` | VARCHAR(20) | Identificacion del estudiante (texto para preservar ceros) |
| `nombre` | VARCHAR(255) | Primer nombre |
| `apellido` | VARCHAR(255) | Apellidos |
| `producto` | VARCHAR(255) | Nombre de la carrera (ej: "Marketing") |
| `modalidad` | VARCHAR(50) | MODALIDAD EN LINEA, POSGRADO, TECNOLOGICO |
| `telefono1` | VARCHAR(20) | Telefono principal |
| `telefono2` | VARCHAR(20) | Telefono secundario |
| `telefono3` | VARCHAR(20) | Telefono adicional |
| `telefono4` | VARCHAR(20) | Telefono adicional |
| `telefono5` | VARCHAR(20) | Telefono adicional |
| `telefono6` | VARCHAR(20) | Telefono adicional |
| `estado_flujo` | VARCHAR(20) DEFAULT 'PENDIENTE' | PENDIENTE, EN_PROCESO, REINTENTAR, FINALIZADO |
| `intentos_llamada` | INTEGER DEFAULT 0 | Contador total de intentos |
| `win_tries` | INTEGER DEFAULT 0 | Intentos en ventana actual |
| `win_stamp` | VARCHAR(50) | Identificador de ventana (ej: "MANANA_2026-05-04") |
| `telefono_index` | INTEGER DEFAULT 0 | Indice 0-5 del telefono en uso |
| `fecha_reagenda` | TIMESTAMPTZ | Fecha/hora del proximo intento |
| `fecha_ultima_llamada` | TIMESTAMPTZ | Timestamp de ultima llamada |
| `created_at` | TIMESTAMPTZ DEFAULT NOW() | Fecha de creacion |
| `updated_at` | TIMESTAMPTZ DEFAULT NOW() | Fecha de actualizacion |

**Constraints:**
- `utpl_registros_pkey`: PRIMARY KEY (id_negocio)
- `idx_utpl_registros_cedula`: INDEX on cedula
- `chk_modalidad`: modalidad IN ('MODALIDAD EN LINEA', 'POSGRADO', 'TECNOLOGICO')
- `chk_estado_flujo`: estado_flujo IN ('PENDIENTE', 'EN_PROCESO', 'REINTENTAR', 'FINALIZADO')
- `chk_intentos_llamada`: intentos_llamada >= 0 AND <= 16
- `chk_win_tries`: win_tries >= 0 AND <= 3
- `chk_telefono_index`: telefono_index >= 0 AND <= 6

**Indices:**
- `idx_utpl_registros_estado` ON estado_flujo
- `idx_utpl_registros_fecha_reagenda` ON fecha_reagenda
- `idx_utpl_registros_intentos` ON intentos_llamada
- `idx_utpl_registros_modalidad` ON modalidad

### 2.2 utpl_llamadas (Log de Llamadas)

| Columna | Tipo | Descripcion |
|---------|------|-------------|
| `id` | BIGSERIAL PK | ID autoincremental |
| `id_llamada` | VARCHAR(100) UNIQUE | ID de la llamada en Vapi |
| `cedula` | VARCHAR(20) FK | FK a utpl_registros |
| `fecha_gestion` | DATE | Fecha de la llamada |
| `hora_gestion` | VARCHAR(10) | Hora en formato HH:MM:SS |
| `hora_inicio_llamada` | TIMESTAMPTZ | Timestamp de inicio (Vapi) |
| `hora_fin_llamada` | TIMESTAMPTZ | Timestamp de fin (Vapi) |
| `duracion_llamada` | INTEGER | Duracion en segundos |
| `id_nomenclatura` | VARCHAR(50) | Codigo: NUE, ACE, IND, VLL, NIN, NC |
| `id_motivo` | VARCHAR(500) | Texto del motivo |
| `ultimo_resultado_llamada` | VARCHAR(100) | endedReason de Vapi |
| `sentimiento` | VARCHAR(50) | Sentimiento detectado |
| `es_familiar` | VARCHAR(5) | Si/No |
| `contactoalo` | VARCHAR(5) | Si/No |
| `contactoefectivo` | VARCHAR(5) | Si/No |
| `transferido` | VARCHAR(5) | Si/No |
| `numero_telefono` | VARCHAR(20) | Numero marcado |
| `transcripcion_llamada` | TEXT | Transcripcion completa |
| `resumen_llamada` | TEXT | Resumen generado por Vapi |
| `link_audio_vapi` | VARCHAR(500) | URL del audio de la llamada |
| `created_at` | TIMESTAMPTZ DEFAULT NOW() | Fecha de creacion |
| `updated_at` | TIMESTAMPTZ DEFAULT NOW() | Fecha de actualizacion |

**Indices:**
- `idx_utpl_llamadas_cedula` ON cedula
- `idx_utpl_llamadas_id_llamada` ON id_llamada
- `idx_utpl_llamadas_fecha_gestion` ON fecha_gestion
- `idx_utpl_llamadas_nomenclatura` ON id_nomenclatura

---

## 3. Flujos n8n - Especificacion Detallada

### 3.1 Flujo: ENTRADA DE DATOS UTPL

**Archivo:** `ENTRADA_DE_DATOS_UTPL.json`
**Trigger:** Webhook `POST /utpl-entrada-datos`

#### Estructura:
```
Webhook ALTIVA UTPL
  └─ PROCESA 1 POR UNO (SplitOut: body.leads)
       └─ MAPEA CAMPOS UTPL (Code node)
            └─ GUARDA EN UTPL REGISTROS (Postgres upsert)
```

#### Mapping ALTIVA → utpl_registros:
| ALTIVA Field | DB Column |
|-------------|-----------|
| `cedula` | `cedula` |
| `nombre` | `nombre` |
| `apellido` | `apellido` |
| `producto` | `producto` |
| `modalidad` | `modalidad` (uppercased) |
| `ph_celular` | `telefono1` |
| `ph_celular2` | `telefono2` |
| `ph_residencial` | `telefono3` |
| `ph_residencial2` | `telefono4` |
| `ph_comercial` | `telefono5` |
| `ph_telefono4` | `telefono6` |

#### Upsert Logic:
- **Matching column:** `cedula`
- **INSERT (nuevo):** Todos los campos de datos + operativos via DB defaults
- **UPDATE (existente):** Solo campos de datos (nombre, apellido, producto, modalidad, telefonos). NO toca estado_flujo ni operativos.

### 3.2 Flujo: UTPL Llamadas

**Archivo:** `utpl_Llamadas.json`
**Trigger:** Schedule Trigger (cada 60 segundos)

#### Config (CONFIG INICIAL UTPL):
```javascript
cfg = {
  runtime: { testMode: false, timeOffsetMinutes: 0 },
  db: { schema: 'public', table: 'utpl_registros', pk: 'cedula' },
  states: { pending: 'PENDIENTE', inProgress: 'EN_PROCESO', retry: 'REINTENTAR', done: 'FINALIZADO' },
  agents: {
    'MODALIDAD EN LINEA': 'cc4bbac0-0736-48f6-8175-0bfe4c4e8a76',
    'POSGRADO': 'd61d17dc-6e48-4ce7-bfdb-3dc40dcd329e',
    'TECNOLOGICO': '638fb59f-0522-4d76-9ca4-a47609f64961'
  },
  vapi: { baseUrl: 'https://api.vapi.ai', apiKey: '484afd71-...', phoneNumberId: '8b04b436-...', sip: '0', campaignId: 'UTPL_LLAMADAS' },
  policy: { TZ: 'America/Guayaquil', CC: '+593', maxLifetimeTries: 16, maxWindowTries: 3, offHoursWait: 30,
    holidays: ['2026-05-25'],
    windows: [
      { id: 'MANANA', days: '1,2,3,4,5', start: '08:00', end: '12:00' },
      { id: 'TARDE', days: '1,2,3,4,5', start: '12:01', end: '14:00' },
      { id: 'NOCHE', days: '1,2,3,4,5', start: '14:01', end: '20:00' }
    ],
    phoneFields: ['telefono1', 'telefono2', 'telefono3', 'telefono4', 'telefono5', 'telefono6']
  },
  noPhoneClassification: { nomenclatura: 'NC', codigo_respuesta: 'NO_CONTACTO', motivo: 'Sin numero de telefono valido' }
}
```

#### Nodos (18 nodos):
1. **EJECUTA ESTO CADA 60 SEG** - Schedule trigger
2. **CONFIG INICIAL UTPL** - Code node con toda la configuracion
3. **BUSCA Y BLOQUEA REGISTRO** - PostgreSQL `SELECT ... FOR UPDATE SKIP LOCKED`
4. **SI SE ENCONTRO REGISTRO** - IF: `$json.cedula exists`
5. **NORMALIZA DATOS** - Limpia y estandariza campos
6. **POLITICAS REGLA 3x3** - Aplica regla de ventanas y selecciona asistente
7. **SI PUEDE LLAMAR** - IF: `$json.puedeLlamar === true`
8. **PROCESA TELEFONOS** - Formatea a E.164, selecciona por telefono_index
9. **FORMATEA STATUS** - Set node para cuando no se puede llamar
10. **GUARDA STATUS** - Upsert estado y fecha_reagenda
11. **SI QUEDAN NUMEROS** - IF: `$json.isOutOfNumbers === false`
12. **CAPTURA SNAPSHOT** - Guarda estado previo para fallback
13. **SIN NUMERO VALIDO** - Marca FINALIZADO si no hay telefonos
14. **GUARDA PRE-LLAMADA** - Incrementa contadores antes de llamar
15. **GUARDA REPORTE** - Upsert cuando no hay numero
16. **LLAMAR VAPI AGENTE** - HTTP POST a Vapi API
17. **FALLBACK RESTORE** - Restaura snapshot si falla
18. **NO HACE NADA** - Nodo terminal

#### Politicas Regla 3x3 - Logica:
```
1. Si es domingo (weekday=7) → reagenda lunes 08:00
2. Si es feriado → reagenda dia siguiente 08:00
3. Si intentos_llamada >= 16 → AGOTADO / FINALIZADO
4. Asignar assistant_id segun modalidad
5. Determinar ventana actual (MANANA/TARDE/NOCHE)
6. Si ventana nueva → reset win_tries, win_stamp = "VENTANA_FECHA"
7. Si win_tries < 3 → puedeLlamar = true
8. Si win_tries >= 3 → reagenda a siguiente ventana
9. Fuera de horario → reagenda a inicio de proxima ventana
```

#### Payload Vapi:
```json
{
  "type": "outboundPhoneCall",
  "name": "Llamada MODALIDAD - NOMBRE_COMPLETO",
  "assistantId": "<segun modalidad>",
  "phoneNumberId": "<config>",
  "customer": { "number": "+593...", "name": "..." },
  "metadata": { "cedula": "...", "modalidad": "...", "producto": "..." },
  "assistantOverrides": {
    "variableValues": {
      "sip": "0", "cedula": "...", "nombre": "...", "nombre_cliente": "...",
      "producto": "...", "modalidad": "...", "modo": "normal", "MODO": "normal"
    }
  }
}
```

### 3.3 Flujo: CIERRE LLAMADAS UTPL

**Archivo:** `utpl_CierreLlamadas.json`
**Trigger:** Webhook `POST /utpl-cierre-vapi` (llamado por Vapi al finalizar llamada)

#### Nodos:
1. **Webhook Cierre VAPI UTPL** - Recibe `end-of-call-report` de Vapi
2. **CONFIG INICIAL UTPL** - Config con retryNomenclaturas: ['NC', 'VLL']
3. **NORMALIZA EVENTO CIERRE UTPL** - Extrae campos del payload Vapi
4. **ES EVENTO CIERRE VALIDO** - Filtra eventos tipo `end-of-call-report`
5. **EXTRAE STRUCTURED OUTPUTS** - Busca 7 outputs por nombre
6. **CLASIFICA ESTADO CIERRE** - NC/VLL → REINTENTAR, resto → FINALIZADO
7. **MAPEA CAMPOS CIERRE UTPL** - Mapea 20 campos para DB
8. **GENERAR QUERY ACTUALIZA** - SQL para UPDATE utpl_registros
9. **ACTUALIZA REGISTRO UTPL** - Ejecuta UPDATE
10. **INSERTA EN LLAMADAS UTPL** - Upsert en utpl_llamadas
11. **FALLBACK RESTORE CIERRE** - Rollback si falla

#### Structured Outputs (7 total):
| Output Name | Busqueda (normalizado) | Campo en DB |
|------------|----------------------|-------------|
| `Estado_Gestion_UTPL` | `estadogestionutpl` | `id_nomenclatura`, `id_motivo` |
| `Sentimiento_Cliente` | `sentimientocliente` | `sentimiento` |
| `Es Familiar` | `esfamiliar` | `es_familiar` |
| `contactoalo` | `contactoalo` | `contactoalo` |
| `contactoefectivo` | `contactoefectivo` | `contactoefectivo` |
| `Resumen_Llamada` | `resumenllamada` | `resumen_llamada` |
| `Cliente_Transferido` | `clientetransferido` | `transferido` |

---

## 4. Nomenclaturas y Motivos

### 4.1 Catalogo Completo

| Nomenclatura | Codigo | Motivo |
|-------------|--------|--------|
| NUE | NUE | Nuevo |
| ACE | ACE | Sin Pago Con Plan De Pagos |
| ACE | ACE | Sin Pago Con Deuda Al Banco |
| ACE | ACE | Sin Pago Con Tarjeta De Credito |
| ACE | ACE | Sin Pago Sin Compromiso De Pago |
| IND | IND | Acept-Costos-Gestionando Beca |
| IND | IND | Acept-Costos-Esperando Beca |
| IND | IND | Acept-Costos-Consultara Con Familia |
| IND | IND | Pendiente Por Confirmar Codigo Validacion |
| IND | IND | Acept-Costos-Necesita Analizar Proceso |
| IND | IND | Acept-Pers-Quiere Pensar Y Leer Info |
| VLL | VLL | Llamar Otro Horario |
| NIN | NIN | Equivocado |
| NIN | NIN | IVR De Empresa |
| NIN | NIN | Continuara por si solo |
| NIN | NIN | Titular Esta Fuera Del Pais |
| NIN | NIN | Tercero o Familiar Pide No Llamar |
| NIN | NIN | Neg-Costos-No Tiene Dinero |
| NIN | NIN | Neg-Pers-Problemas De Salud |
| NIN | NIN | Informacion Para Un Familiar |
| NIN | NIN | Neg-Pers-Aun No Es Bachiller |
| NIN | NIN | Negativa-Pers-Titular Fallecido |
| NIN | NIN | Estudiante Utpl 2Do. En Adelante |
| NIN | NIN | Negativa-Pers-Trabaja En La Utpl |
| NIN | NIN | Neg-Academicos-Interesado En Maestria |
| NIN | NIN | Indica Que No Ha Solicitado Informacion |
| NIN | NIN | Neg-Academicos-Mala Experiencia Con Utpl |
| NIN | NIN | Neg-Tiempo-No Tiene Tiempo Para Estudiar |
| NIN | NIN | No Esta Interesado En Modalidad En Linea |
| NIN | NIN | No Desea Continuar Con Proceso Matricula |
| NIN | NIN | Neg-Academicos-Estudia Ahora En Otra Univ |
| NIN | NIN | Neg-Academicos-Carreras Ofertadas No Desea |
| NIN | NIN | Neg-Academicos-Interesado Cursos Form. Perm |
| NC | NC | No Contacto |
| NC | NC | Numero incorrecto |

### 4.2 Reglas de Reintento por Nomenclatura
- **VLL** (VOLVER A LLAMAR) → `estado_flujo = REINTENTAR`
- **NC** (NO CONTACTO) → `estado_flujo = REINTENTAR`
- **Resto** → `estado_flujo = FINALIZADO`

---

## 5. Configuracion Vapi

### 5.1 Endpoints
- **Base URL:** `https://api.vapi.ai`
- **Call endpoint:** `POST /call`
- **API Key:** `484afd71-2703-4852-8580-9629620dde82`

### 5.2 Asistentes
| ID | Nombre | Modalidad |
|----|--------|-----------|
| `cc4bbac0-0736-48f6-8175-0bfe4c4e8a76` | utpl mel | MODALIDAD EN LINEA |
| `d61d17dc-6e48-4ce7-bfdb-3dc40dcd329e` | utpl posgrado | POSGRADO |
| `638fb59f-0522-4d76-9ca4-a47609f64961` | utpl tecnologico | TECNOLOGICO |

### 5.3 Phone Numbers
| ID | Uso |
|----|-----|
| `8b04b436-544e-4054-b4ac-474048ca5323` | n8n production flow |
| `984fc4c1-d501-47cc-b347-f4fe78085d33` | pruebas-tool |

### 5.4 Server URL (Vapi callback)
- **Webhook URL:** `https://n8nps.plusservices.ec/webhook/utpl-cierre-vapi`

### 5.5 Variable Values enviadas al asistente
```
sip, cedula, nombre, nombre_cliente, producto, modalidad, modo, MODO
```

---

## 6. Herramientas Auxiliares

### 6.1 pruebas-tool/index.html
- **Proposito:** Pruebas manuales de llamadas Vapi
- **Ejecucion:** Abrir directamente en navegador (sin servidor)
- **Funcionalidad:** Select de asistente, formulario con datos del lead, boton Llamar
- **Payload:** Mismo formato que el flujo n8n de llamadas

### 6.2 upload_database/
- **Proposito:** Carga masiva de datos Excel/CSV/TXT a Supabase
- **Archivos:** `index.html`, `app.js`, `style.css`
- **Tabla destino:** `utpl_registros`
- **Upsert key:** `cedula`
- **Formatos soportados:** `.xlsx`, `.csv`, `.txt` (tab-delimited)
- **Dry-run mode:** Disponible

---

## 7. Credenciales

| Recurso | ID / Key | Notas |
|---------|----------|-------|
| Supabase URL | `https://suokpkpzpfvadwemxzfa.supabase.co` | |
| Supabase Anon Key | `eyJhbGciOiJIUzI1NiIs...` | Public |
| n8n Postgres | `Gea_postgress` (ID: `Iz7EEp0WgJu3LXhn`) | n8n credential |
| Vapi API Key | `484afd71-2703-4852-8580-9629620dde82` | **Cambiar en produccion** |
| Vapi Phone (n8n) | `8b04b436-544e-4054-b4ac-474048ca5323` | |
| Vapi Phone (test) | `984fc4c1-d501-47cc-b347-f4fe78085d33` | |
| n8n Host | `n8nps.plusservices.ec` | |
| n8n Instance ID | `915a7f7568d882a64f47657d6f3fab09c88f51183cb22a1bfa48ee39cc137bcd` | |
| GitHub | `m1gu/utpl-vozia` | |

---

## 8. Formato de Telefonos

- **Country Code:** +593 (Ecuador)
- **Formato:** E.164 (`+593XXXXXXXXX`)
- **Validacion:** >= 9 digitos
- **Limpieza:** Se remueven todos los caracteres no numericos
- **Prefijo:** Si empieza con `0` → reemplazar con `+593`. Si no tiene `+` → agregar `+593`

---

## 9. Timezone y Horarios

- **Zona horaria:** `America/Guayaquil` (UTC-5)
- **Dias laborables:** Lunes a Viernes (weekday 1-5)
- **Domingo:** Sin llamadas (weekday 7), reagendar a lunes 8am
- **Feriados:** `2026-05-25` (Lunes)
- **Ventanas de llamada:** MANANA 08:00-12:00, TARDE 12:01-14:00, NOCHE 14:01-20:00

---

## 10. Manejo de Errores

### 10.1 Flujo Llamadas
- **BUSCA Y BLOQUEA:** onError → continueRegularOutput (sin registro, sigue)
- **GUARDA PRE-LLAMADA:** onError → continueErrorOutput → FALLBACK RESTORE
- **LLAMAR VAPI:** onError → continueErrorOutput → FALLBACK RESTORE
- **FALLBACK RESTORE:** Restaura snapshot o resetea a PENDIENTE

### 10.2 Flujo Cierre
- **MAPEA CAMPOS:** onError → FALLBACK RESTORE CIERRE
- **INSERTA LLAMADAS:** onError → continueErrorOutput → FALLBACK RESTORE CIERRE
- **FALLBACK RESTORE CIERRE:** Restaura estado_flujo al snapshot

---

## 11. RAG - Base de Conocimiento

### 11.1 Arquitectura

```
BaseConocimiento/
  ├── Mel/*.docx (26 archivos)      → modalidad = 'MODALIDAD EN LINEA'
  ├── Posgrado/*.docx (20 archivos) → modalidad = 'POSGRADO'
  ├── Tecnologico/*.docx (5 archivos) → modalidad = 'TECNOLOGICO'
  └── BANCO DE PREGUNTAS Y RESPUESTAS.docx → modalidad = 'general'

  indexar_conocimiento.js
    ├── mammoth (extrae texto de .docx)
    ├── chunking (1800 chars, overlap 200)
    ├── OpenAI text-embedding-3-small (1536 dims)
    └── Supabase pgvector (tabla utpl_conocimiento)
```

### 11.2 Tabla utpl_conocimiento

| Columna | Tipo | Descripcion |
|---------|------|-------------|
| `id` | BIGSERIAL PK | |
| `modalidad` | VARCHAR(50) | MODALIDAD EN LINEA, POSGRADO, TECNOLOGICO, general |
| `fuente` | VARCHAR(255) | Nombre del archivo .docx |
| `titulo` | VARCHAR(500) | Titulo del chunk |
| `contenido` | TEXT | Texto del chunk |
| `embedding` | vector(1536) | OpenAI text-embedding-3-small |
| `metadata` | JSONB | `{archivo, chunk_index, total_chunks}` |
| `created_at` | TIMESTAMPTZ | |

**Indice:** Sin indice ivfflat (exact search con operador `<=>` por pocos datos <1000 filas). Recrear cuando haya 1000+ filas.

### 11.3 Funcion de Busqueda

```sql
buscar_conocimiento_utpl(
  query_embedding vector(1536),
  p_modalidad VARCHAR,     -- filtra por modalidad + general
  p_limit INT DEFAULT 3
)
RETURNS TABLE(id, titulo, contenido, fuente, similitud)
```

Usa cosine distance (`<=>`) con filtro de modalidad. Sin indice ivfflat, busca exacta sobre 173 filas.

### 11.4 Flujo RAG Buscar (utpl_RAG_buscar.json)

**Trigger:** Webhook `POST /utpl-rag-buscar`

**Nodos:**
1. Webhook RAG Buscar (responseMode: responseNode)
2. PREPARA EMBEDDING: Extrae `toolCallId`, `pregunta`, `modalidad` de `message.toolCallList[0].function.arguments`
3. TIENE PREGUNTA?: Valida pregunta
4. RESPUESTA ERROR (false path): Devuelve error en formato Vapi
5. OPENAI EMBEDDINGS: POST a `/v1/embeddings` con `text-embedding-3-small`
6. EXTRAE VECTOR: Extrae el vector del response
7. BUSCAR EN SUPABASE: Ejecuta `buscar_conocimiento_utpl()`
8. FORMATEA RESPUESTA: Wraps en `{ results: [{ toolCallId, result }] }`
9. RESPONDE A VAPI: RespondToWebhook con JSON

**Input Vapi format:**
```json
{
  "message": {
    "toolCallList": [{
      "id": "toolu_xxx",
      "function": {
        "arguments": {
          "pregunta": "cuanto cuesta Marketing?",
          "modalidad": "MODALIDAD EN LINEA"
        }
      }
    }]
  }
}
```

**Output Vapi format:**
```json
{
  "results": [{
    "toolCallId": "toolu_xxx",
    "result": "[1] (Marketing.docx) La carrera de Marketing..."
  }]
}
```

### 11.5 Vapi Tool Configuration

Cada asistente tiene un Custom Function:
- **Name:** `buscar_rag_utpl`
- **URL:** `https://n8nps.plusservices.ec/webhook/utpl-rag-buscar`
- **Parameters:** `pregunta` (string), `modalidad` (string, fija por asistente)
- **Tool ID:** `69b0481a-90d7-41f0-bc82-810136c397a6`

### 11.6 Script de Indexacion

```bash
npm install mammoth openai @supabase/supabase-js dotenv
# Configurar OPENAI_API_KEY en .env
node scripts/indexar_conocimiento.js
```

- 52 archivos → 173 chunks → 173 embeddings
- Costo OpenAI: ~$0.01-0.05 total
- Re-ejecutar cuando se actualicen documentos
- Dependencias: `mammoth`, `openai`, `@supabase/supabase-js`, `dotenv`
