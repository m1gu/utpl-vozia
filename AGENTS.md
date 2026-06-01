# UTPL VozIA - Agent Quick Reference

## Project Identity
- **Project**: UTPL VozIA - Sistema automatizado de llamadas para captacion de estudiantes
- **Client**: Universidad Tecnica Particular de Loja (UTPL)
- **GitHub**: `m1gu/utpl-vozia`
- **n8n Host**: `n8nps.plusservices.ec`

---

## Architecture Overview

```
ALTIVA ──POST──► UTPL INGRESO LEAD ──► Supabase (utpl_registros)
                                                  │
                              ┌───────────────────┘
                              ▼
                    EJECUTA CADA 20 SEG (Schedule)
                              │
                              ▼
                    BUSCA Y BLOQUEA REGISTRO
                              │
                              ▼
                    POLITICAS REGLA 3x3
                              │
                    ┌─────────┴─────────┐
                    ▼                   ▼
            LLAMAR VAPI AGENTE    FORMATEA STATUS
                    │                   │
                    ▼                   ▼
              ┌──────────┐      GUARDA STATUS
              │ Vapi Call │             │
              └──────────┘      (si AGOTADO → CRM)
                    │                   │
                    ▼                   ▼
          CIERRE LLAMADAS UTPL    NOTIFICA CRM UTPL
                    │             (SOAP RegistrarLLamada)
          ┌─────────┼──────────┐
          ▼         ▼          ▼
   ACTUALIZA   INSERTA EN   NOTIFICA CRM UTPL
   REGISTRO    LLAMADAS     (si NIN → keyword match)
```

---

## Flows Summary

| Flow | File | Trigger | Purpose |
|------|------|---------|---------|
| Ingreso Lead | `UTPL_INGRESO_LEAD.json` | Webhook `utpl-ingreso-lead` | CRM externo → Supabase (con auth) |
| Llamadas | `Utpl_Llamadas.json` | Schedule (20s) | Pick records, apply 3x3 rule, call Vapi, notify CRM on exhausted |
| Cierre Llamadas | `Utpl_CierreLlamadas.json` | Webhook `utpl-cierre-vapi` | Vapi end-of-call → update DB, notify CRM on NIN |
| RAG Buscar | `UTPL_RAG_buscar.json` | Webhook `utpl-rag-buscar` | Vapi tool: busqueda semantica en conocimiento |
| Simulador | `UTPL_SIMULADOR.json` | Webhook `utpl-simulador` | Test: recibe "llamada" → genera cierre sintetico → CierreLlamadas |

---

## Tables (Supabase)

| Table | PK / Match | Purpose |
|-------|-----------|---------|
| `utpl_registros` | `id_negocio` (PK) / `cedula` | Main lead registry with operative fields |
| `utpl_llamadas` | `id_llamada` | Call log (every call attempt recorded) |
| `utpl_crm` | `id` | Audit log of SOAP requests sent to CRM UTPL |
| `utpl_config` | `key` | Key-value config store (tokens, credentials) |
| `utpl_conocimiento` | `id` | RAG knowledge base (pgvector embeddings) |

### utpl_registros - Key Columns
**Data**: id_negocio (PK), id_interno_negocio, cedula, nombre, apellido, producto, modalidad, nombre_corto_campania
**Phones**: telefono1..telefono6
**Operative**: estado_flujo, intentos_llamada, win_tries, win_stamp, telefono_index, fecha_reagenda, fecha_ultima_llamada, updated_at

### utpl_llamadas - Key Columns
id_llamada, cedula, fecha_gestion, hora_gestion, id_nomenclatura, id_motivo, sentimiento, transcripcion_llamada, resumen_llamada, link_audio_vapi, ultimo_resultado_llamada, es_familiar, duracion_llamada, transferido, contactoalo, contactoefectivo, numero_telefono

---

## Vapi Configuration

| Modality | Assistant ID | Vapi Name |
|----------|-------------|-----------|
| MODALIDAD EN LINEA | `cc4bbac0-0736-48f6-8175-0bfe4c4e8a76` | utpl mel |
| POSGRADO | `d61d17dc-6e48-4ce7-bfdb-3dc40dcd329e` | utpl posgrado |
| TECNOLOGICO | `638fb59f-0522-4d76-9ca4-a47609f64961` | utpl tecnologico |

**Phone Number ID**: `8b04b436-544e-4054-b4ac-474048ca5323` (n8n flow) / `984fc4c1-d501-47cc-b347-f4fe78085d33` (test tool)
**API Key**: `484afd71-2703-4852-8580-9629620dde82` (CHANGE THIS FOR PRODUCTION)
**Structured Outputs** (7 total, shared across 3 assistants):
- `Estado_Gestion_UTPL` → id_nomenclatura, id_motivo
- `Sentimiento_Cliente` → sentimiento
- `Es Familiar` → es_familiar
- `contactoalo` → contactoalo
- `contactoefectivo` → contactoefectivo
- `Resumen_Llamada` → resumen_llamada
- `Cliente_Transferido` → transferido

---

## 3x3 Dialing Rule

| Window | Hours | Max Tries |
|--------|-------|-----------|
| MANANA | 08:00 - 12:00 | 3 |
| TARDE | 12:01 - 14:00 | 3 |
| NOCHE | 14:01 - 20:00 | 3 |

- **Max lifetime tries**: 16 per record
- **Days**: Monday to Friday only (Sunday = reschedule to Mon 8am)
- **Holidays**: `2026-05-25` (reschedules to next day)
- **Timezone**: `America/Guayaquil`
- **Phone cycling**: Sequential via telefono_index % phones.length

---

## Estados del Flujo

```
PENDIENTE → EN_PROCESO → REINTENTAR → PENDIENTE (cycle)
                       → FINALIZADO (done)
```

---

## Nomenclaturas (UTPL)

| Code | Name | Retry? |
|------|------|--------|
| NUE | NUEVO | No (FINALIZADO) |
| ACE | ACEPTACION | No (FINALIZADO) |
| IND | INDECISO | No (FINALIZADO) |
| VLL | VOLVER A LLAMAR | **YES (REINTENTAR)** |
| NIN | NO INTERESADO | No (FINALIZADO) |
| NC | NO CONTACTO | **YES (REINTENTAR)** |

---

## Estado del Flujo: Estados

| Estado | Meaning |
|--------|---------|
| `PENDIENTE` | New/unprocessed, ready to be picked |
| `EN_PROCESO` | Currently being dialed |
| `REINTENTAR` | Dial attempted, needs retry later |
| `FINALIZADO` | Processing complete |

---

## Tools

| Tool | Path | Purpose |
|------|------|---------|
| Vapi Test | `pruebas-tool/index.html` | Manual Vapi call testing |
| Upload DB | `upload_database/` | Excel → Supabase bulk upload |
| Indexar KB | `scripts/indexar_conocimiento.js` | .docx → chunks → embeddings → Supabase |
| Simulador | `flujo_n8n/UTPL_SIMULADOR.json` | Synthetic Vapi calls for flow testing |
| Cargar Prueba | `scripts/cargar_datos_prueba.js` | Generate 100 test leads SQL |
| Validar SQL | `scripts/validar_sql.js` | Validate constraints in test SQL |

---

## RAG Knowledge Base

**Table**: `utpl_conocimiento` (pgvector)
**Flow**: `UTPL_RAG_buscar.json` — Webhook `POST /utpl-rag-buscar`
**Embeddings provider**: OpenAI `text-embedding-3-small`

### Architecture
```
BaseConocimiento/*.docx ──► indexar_conocimiento.js ──► Supabase pgvector
                                                                  │
Vapi Assistant ──Tool Call──► n8n /utpl-rag-buscar ───► OpenAI embed
     ▲                          │                              │
     │                          ▼                              ▼
     └──── results[] ──── RESPONDE A VAPI ◄─── buscar_conocimiento_utpl()
```

### Vapi Tool Format
**Input** (n8n recibe): `message.toolCallList[0].function.arguments` → `{ pregunta, modalidad }`
**Output** (n8n responde): `{ results: [{ toolCallId: "...", result: "contexto" }] }`

### Index Update
```bash
npm install mammoth openai @supabase/supabase-js dotenv
# Set OPENAI_API_KEY in .env
node scripts/indexar_conocimiento.js
```
- 52 .docx files → 173 chunks indexed
- Index `ivfflat` dropped (exact cosine search, fast with <1000 rows)
- Re-run when documents are updated

---

## Supabase Connection
- **URL**: `https://suokpkpzpfvadwemxzfa.supabase.co`
- **Anon Key**: `eyJhbGciOiJIUzI1NiIs...Vln72A`
- **Postgres Credential** (n8n): `Gea_postgress` (ID: `Iz7EEp0WgJu3LXhn`)

---

## CRM UTPL Integration

### SOAP Web Service
- **Endpoint**: `http://192.168.10.112/WSUtpl/ServiceUtpl.asmx`
- **Action**: `RegistrarLLamada` (SOAP 1.1)
- **Agent name**: `ARIA UTPL`
- **Timeout**: 30s

### When CRM is notified
| Scenario | Trigger | Flow |
|----------|---------|------|
| NIN (lead not interested) | Vapi returns NIN → FINALIZADO | `CierreLlamadas` → `ENVIA A CRM UTPL` |
| Max attempts exhausted (AGOTADO) | `intentos_llamada >= 16` → FINALIZADO | `Llamadas` → `SI FINAL AGOTADO` → `ENVIA A CRM UTPL` |

### NIN Sub-motivo Mapping (keyword matching on resumen_llamada)
The CRM catalog (`Docs/Motivos_CRM_UTPL.csv`) defines 22 NIN sub-reasons mapped to HubSpot `hs_call_disposition` UUIDs:
- **dealstage NIN (NO INTERESADO)**: `1020923926`
- **dealstage NC (NO CONTACTO)**: `1008735099`

Keyword matching is applied on `resumen_llamada` + `transcripcion_llamada` to select the best-fitting sub-motivo. Default: `NIN - No Desea Continuar Con Proceso Matricula`.

### AGOTADO default
When max attempts exhausted: `NIN - No Localizable` (UUID: `fa9b4696-95d1-4b4a-906f-4b0b7b7f155b`)

### Response handling
- Success: `<httpCode>201</httpCode>` + `<idreturn>`
- Error: `<messagews1>` / `<messagews2>` / `<messagews3>` (logged, flow not interrupted)

### Config (CONFIG INICIAL UTPL)
```js
crmUtpl: {
  triggerNomenclaturas: ['NIN'],
  wsUrl: 'http://192.168.10.112/WSUtpl/ServiceUtpl.asmx',
  soapAction: 'http://tempuri.org/RegistrarLLamada',
  agentName: 'ARIA UTPL',
  dealstage: { NIN: '1020923926', NC: '1008735099' },
  defaultDisposition: {
    agotado: { disposition: 'fa9b4696-95d1-4b4a-906f-4b0b7b7f155b', subEstado: 'NIN - No Localizable' }
  }
}
```

### CierreLlamadas CRM branch (parallel, non-blocking)
```
MAPEA CAMPOS CIERRE UTPL
  ├── GENERAR QUERY ACTUALIZA (existing)
  └── CONDICION ENVIO CRM UTPL (IF: id_nomenclatura === 'NIN')
        └── MAPEA MOTIVO CRM UTPL (keyword matching)
              └── PREPARA SOAP XML UTPL (builds SOAP 1.1 envelope)
                    └── ENVIA A CRM UTPL (HTTP POST)
                          └── PROCESA RESPUESTA CRM UTPL (parse XML)
                                └── INSERTA EN CRM UTPL (audit log)
```

### Llamadas CRM branch (AGOTADO)
```
GUARDA STATUS
  └── SI FINAL AGOTADO (IF: status_sugerido === 'AGOTADO')
        ├── PREPARA SOAP XML AGOTADO (fixed values: NIN-No Localizable)
        │     └── ENVIA A CRM UTPL (HTTP POST)
        │           └── PROCESA RESPUESTA CRM UTPL (parse XML)
        │                 └── INSERTA EN CRM UTPL (audit log)
        └── LEE TOKEN ALTIVA → ... → ACTUALIZA NODO ALTIVA (HTTP POST)
```

---

## Altiva Integration

### Web Service
- **Endpoint**: `http://192.168.10.238:91/api/v1/altiva/nodo/actualizar`
- **Auth endpoint**: `http://192.168.10.238:91/api/auth/token` (JWT, 24h expiry)
- **Token cache**: `utpl_config` table (key: `altiva_token`)
- **Agent name**: `ARIA UTPL`

### When Altiva is notified
| Scenario | Trigger | nodo |
|----------|---------|------|
| Lead not interested (NIN) | Vapi returns NIN → FINALIZADO | `1` |
| Lead interested (ACE/IND/NUE) | Vapi returns ACE/IND/NUE → FINALIZADO | `2` |
| Max attempts exhausted (AGOTADO) | `intentos_llamada >= 16` | `1` |

### CierreLlamadas Altiva branch (parallel, non-blocking)
```
MAPEA CAMPOS CIERRE UTPL
  └── CONDICION ENVIO ALTIVA (IF: estado_flujo === 'FINALIZADO')
        └── LEE TOKEN ALTIVA (Postgres SELECT utpl_config)
              └── DECIDE FLUJO TOKEN (check expiry)
                    └── NECESITA REFRESH TOKEN (IF)
                          ├── SI → SOLICITA TOKEN → GUARDA TOKEN
                          └── NO → JOIN ALTIVA TOKEN
                                    └── PREPARA CARGA ALTIVA (build body)
                                          └── ACTUALIZA NODO ALTIVA (HTTP POST)
                                                └── PROCESA RESPUESTA ALTIVA
```

### Config (CONFIG INICIAL UTPL)
```js
altiva: {
  urlBase: 'http://192.168.10.238:91',
  clientId: '7',
  clientSecret: 'ug7wMESTpOPPmdDC3KoEyYpVXskcOqRWnfHFZm8X',
  nombreCampania: 'TEMP_PLACEHOLDER',
  nodoMapping: { NIN: '1', ACE: '2', IND: '2', NUE: '2' }
}
```

---

## SFTP Audio Download

### When triggered
Every time a Vapi call ends and `link_audio_vapi` is present in the callback.

### Flow (parallel, non-blocking)
```
INSERTA EN CRM UTPL
  └── CONDICION AUDIO (IF: link_audio_vapi exists)
        └── DESCARGAR AUDIO (HTTP GET → binary, timeout 300s)
              └── PROCESAR AUDIO (detect ext: mp3/wav)
                    └── SUBIR AUDIO SFTP (FTP upload)
                          Path: /UTPL/llamadas/YYYYMMDD/{id_llamada}.{ext}
```

### SFTP Credential
Same as Solidario: `SFTP account` (ID: `vEofEOfYOxdhgSvj`)

---

## Modalidades Validas
`MODALIDAD EN LINEA`, `POSGRADO`, `TECNOLOGICO`
