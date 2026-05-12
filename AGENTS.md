# UTPL VozIA - Agent Quick Reference

## Project Identity
- **Project**: UTPL VozIA - Sistema automatizado de llamadas para captacion de estudiantes
- **Client**: Universidad Tecnica Particular de Loja (UTPL)
- **GitHub**: `m1gu/utpl-vozia`
- **n8n Host**: `n8nps.plusservices.ec`

---

## Architecture Overview

```
ALTIVA ──POST──► ENTRADA DE DATOS UTPL ──► Supabase (utpl_registros)
                                                    │
                              ┌─────────────────────┘
                              ▼
                    EJECUTA CADA 60 SEG (Schedule)
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
              │ Vapi Call │
              └──────────┘
                    │ (webhook callback)
                    ▼
          CIERRE LLAMADAS UTPL
                    │
          ┌─────────┴──────────┐
          ▼                    ▼
   ACTUALIZA REGISTRO    INSERTA EN LLAMADAS
```

---

## Flows Summary

| Flow | File | Trigger | Purpose |
|------|------|---------|---------|
| Entrada Datos | `ENTRADA_DE_DATOS_UTPL.json` | Webhook `utpl-entrada-datos` | ALTIVA → Supabase |
| Ingreso Lead | `UTPL_INGRESO_LEAD.json` | Webhook `utpl-ingreso-lead` | CRM externo → Supabase (con auth) |
| Llamadas | `utpl_Llamadas.json` | Schedule (60s) | Pick records, apply 3x3 rule, call Vapi |
| Cierre Llamadas | `utpl_CierreLlamadas.json` | Webhook `utpl-cierre-vapi` | Vapi end-of-call → update DB |
| RAG Buscar | `utpl_RAG_buscar.json` | Webhook `utpl-rag-buscar` | Vapi tool: busqueda semantica en conocimiento |

---

## Tables (Supabase)

| Table | PK / Match | Purpose |
|-------|-----------|---------|
| `utpl_registros` | `id_negocio` (PK) / `cedula` | Main lead registry with operative fields |
| `utpl_llamadas` | `id_llamada` | Call log (every call attempt recorded) |
| `utpl_conocimiento` | `id` | RAG knowledge base (pgvector embeddings) |

### utpl_registros - Key Columns
**Data**: id_negocio (PK), cedula, nombre, apellido, producto, modalidad
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

## Modalidades Validas
`MODALIDAD EN LINEA`, `POSGRADO`, `TECNOLOGICO`
