# Plan: Módulo de Reglas de Marcado — `dialing-rules-engine`

> **Proyecto**: UTPL VozIA  
> **Fecha**: 2026-05-20  
> **Objetivo**: Extraer la lógica de reglas de marcado de los flujos n8n a un módulo Python independiente con API REST, UI de administración y almacenamiento en Supabase, capaz de servir a múltiples campañas/clientes.

---

## Índice

1. [Arquitectura General](#1-arquitectura-general)
2. [Modelo de Datos](#2-modelo-de-datos)
3. [Fase 1 — Modelo de Datos, Migraciones y Schemas](#fase-1--modelo-de-datos-migraciones-y-schemas)
4. [Fase 2 — CRUD API Endpoints](#fase-2--crud-api-endpoints)
5. [Fase 3 — Motor de Evaluación](#fase-3--motor-de-evaluación)
6. [Fase 4 — UI de Administración](#fase-4--ui-de-administración)
7. [Fase 5 — Integración con n8n](#fase-5--integración-con-n8n)
8. [Fase 6 — Pruebas, Migración y Puesta en Marcha](#fase-6--pruebas-migración-y-puesta-en-marcha)
9. [Riesgos y Mitigaciones](#9-riesgos-y-mitigaciones)
10. [Stack Tecnológico Final](#10-stack-tecnológico-final)

---

## 1. Arquitectura General

```
┌──────────────────────────────────────────────────────────────────┐
│                     dialing-rules-engine                          │
│                                                                   │
│  ┌─────────────────┐   ┌────────────────────┐   ┌─────────────┐  │
│  │   FastAPI (async)│   │   Rules Engine     │   │  Supabase   │  │
│  │   REST API       │──▶│   (core Python)    │──▶│  PostgreSQL │  │
│  └────────┬────────┘   └────────────────────┘   └─────────────┘  │
│           │                                                        │
│           ├──► /api/v1/evaluate   ◄── n8n UTPL / Solidario / ... │
│           ├──► /api/v1/classify   ◄── n8n UTPL / Solidario / ... │
│           └──► /api/v1/campaigns* ◄── Admin UI                    │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  Admin UI (React + shadcn/ui + Tailwind)                     │  │
│  │  /campaigns  /campaigns/:id/windows  /campaigns/:id/rules    │  │
│  │  /campaigns/:id/holidays                                     │  │
│  └─────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────┘
```

### Principio de diseño

Cada regla de marcado sigue el patrón:

```
Motivo + Acción + Estrategia de Número + Tiempo de Espera
```

| Campo | Descripción | Ejemplos |
|-------|-------------|----------|
| **Motivo** | Qué dispara la regla | `busy`, `voicemail`, `no_answer`, `failed`, `nom_NC`, `nom_VLL` |
| **Acción** | Qué hacer | `retry` (reintentar), `finalize` (cerrar), `escalate` (escalar a humano), `next_window`, `next_day` |
| **Estrategia** | Qué número marcar | `same_number`, `next_number`, `same_index` |
| **Tiempo** | Cuánto esperar | Minutos antes del siguiente intento |

Ejemplo concreto:
> **Suena ocupado** → **Volver a llamar** → **Mismo número** → **5 minutos**

> **Buzón de voz** → **Volver a llamar** → **Siguiente número** → **15 minutos**

> **No contesta** → **Volver a llamar** → **Mismo número** → **30 minutos**

### Diseño multi-proyecto / multi-tabla

El motor es **agnóstico de la tabla de registros**. No consulta directamente `utpl_registros`, `solidario_registros`, ni ninguna tabla de negocio. Los datos del lead se reciben en cada request vía JSON desde n8n.

```
            ┌──────────────────────────────────────────────┐
            │            dialing-rules-engine               │
            │                                               │
            │  Solo conoce sus tablas:                      │
            │  dialing_campaigns, dialing_windows,          │
            │  dialing_holidays, dialing_motive_rules,      │
            │  dialing_attempts_log                         │
            │                                               │
            └────▲──────────────▲──────────────▲────────────┘
                 │              │              │
           POST /evaluate  /classify    Admin UI
                 │              │
    ┌────────────┴──────┬───────┴────────────┐
    │                    │                    │
    ▼                    ▼                    ▼
┌──────────┐      ┌───────────┐      ┌───────────┐
│ n8n UTPL │      │n8n Solidar│      │n8n Cliente│
│ Flujo    │      │io Flujo   │      │ X Flujo   │
│          │      │           │      │           │
│ Lee:     │      │ Lee:      │      │ Lee:      │
│ utpl_    │      │ solidario_│      │ cliente_  │
│ registros│      │ registros │      │ registros │
│          │      │           │      │           │
│ Normaliza│      │ Normaliza │      │ Normaliza │
│ campos → │      │ campos →  │      │ campos →  │
│ JSON     │      │ JSON      │      │ JSON      │
└────┬─────┘      └─────┬─────┘      └─────┬─────┘
     │                  │                  │
     ▼                  ▼                  ▼
  campaign_slug:     campaign_slug:     campaign_slug:
  "utpl-vozia"       "solidario"        "cliente-x"
```

**Contrato**: n8n normaliza los campos del lead al formato estándar del motor antes de llamar `/evaluate` o `/classify`. Cada flujo de n8n conoce su tabla de registros y mapea los campos. El motor solo necesita `campaign_slug` para saber qué reglas aplicar.

**¿Qué pasa si un proyecto tiene campos diferentes?**  
n8n absorbe la diferencia. Ejemplo: si `solidario_registros` tiene `phone_1` en vez de `telefono1`, el Code node en n8n mapea `telefono1 = phone_1` antes de enviar al motor. El contrato del motor no cambia.

---

## 2. Modelo de Datos

### Supabase — Tablas nuevas creadas en el mismo proyecto UTPL

```sql
-- ═══════════════════════════════════════════════════════════════
-- Tabla: dialing_campaigns
-- Una campaña por cada cliente o línea de negocio
-- ═══════════════════════════════════════════════════════════════
CREATE TABLE dialing_campaigns (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name                TEXT NOT NULL,                          -- Nombre legible: "UTPL Captación"
  slug                TEXT UNIQUE NOT NULL,                   -- Identificador URL: "utpl-vozia"
  description         TEXT,
  tz                  TEXT NOT NULL DEFAULT 'America/Guayaquil',
  cc                  TEXT NOT NULL DEFAULT '+593',            -- Country code por defecto
  max_lifetime_tries  INT NOT NULL DEFAULT 16,                 -- Máximos intentos totales
  max_window_tries    INT NOT NULL DEFAULT 3,                  -- Máximos intentos por ventana
  off_hours_wait_min  INT NOT NULL DEFAULT 30,                 -- Minutos de espera fuera de horario
  active              BOOLEAN NOT NULL DEFAULT true,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ═══════════════════════════════════════════════════════════════
-- Tabla: dialing_windows
-- Ventanas de marcado por campaña (ej: MAÑANA 08:00-12:00)
-- ═══════════════════════════════════════════════════════════════
CREATE TABLE dialing_windows (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_id   UUID NOT NULL REFERENCES dialing_campaigns(id) ON DELETE CASCADE,
  name          TEXT NOT NULL,
  days_csv      TEXT NOT NULL,              -- "1,2,3,4,5" (Lun-Vie), "6" (Sáb), "7" (Dom)
  start_time    TIME NOT NULL,              -- 08:00
  end_time      TIME NOT NULL,              -- 12:00
  sort_order    INT NOT NULL DEFAULT 0,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ═══════════════════════════════════════════════════════════════
-- Tabla: dialing_holidays
-- Feriados por campaña
-- ═══════════════════════════════════════════════════════════════
CREATE TABLE dialing_holidays (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_id   UUID NOT NULL REFERENCES dialing_campaigns(id) ON DELETE CASCADE,
  holiday_date  DATE NOT NULL,
  description   TEXT,
  UNIQUE(campaign_id, holiday_date)
);

-- ═══════════════════════════════════════════════════════════════
-- Tabla: dialing_motive_rules
-- El corazón del sistema: reglas por motivo
-- ═══════════════════════════════════════════════════════════════
CREATE TABLE dialing_motive_rules (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_id     UUID NOT NULL REFERENCES dialing_campaigns(id) ON DELETE CASCADE,
  motive          TEXT NOT NULL,             -- busy, voicemail, no_answer, failed, nom_NC, etc.
  description     TEXT,
  action          TEXT NOT NULL              -- retry, finalize, escalate, next_window, next_day
    CHECK (action IN ('retry','finalize','escalate','next_window','next_day')),
  phone_strategy  TEXT NOT NULL DEFAULT 'same_number'
    CHECK (phone_strategy IN ('same_number','next_number','same_index','next_index')),
  wait_minutes    INT NOT NULL DEFAULT 5,
  max_retries     INT NOT NULL DEFAULT 3,    -- Intentos máximos con este motivo
  sort_order      INT NOT NULL DEFAULT 0,
  active          BOOLEAN NOT NULL DEFAULT true,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(campaign_id, motive)
);

-- ═══════════════════════════════════════════════════════════════
-- Tabla: dialing_attempts_log (opcional — para auditoría)
-- ═══════════════════════════════════════════════════════════════
CREATE TABLE dialing_attempts_log (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_id     UUID NOT NULL REFERENCES dialing_campaigns(id),
  id_negocio      TEXT NOT NULL,
  cedula          TEXT NOT NULL,
  motive          TEXT NOT NULL,             -- Motivo del resultado anterior
  phone_used      TEXT NOT NULL,             -- Número que se marcó
  phone_index     INT NOT NULL,              -- Índice del teléfono usado
  action_taken    TEXT NOT NULL,             -- Acción tomada por el motor
  next_schedule   TIMESTAMPTZ,               -- Cuándo se reprogramó
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Índices
CREATE INDEX idx_windows_campaign ON dialing_windows(campaign_id, sort_order);
CREATE INDEX idx_rules_campaign   ON dialing_motive_rules(campaign_id, sort_order);
CREATE INDEX idx_holidays_campaign ON dialing_holidays(campaign_id, holiday_date);
CREATE INDEX idx_attempts_lead    ON dialing_attempts_log(id_negocio, created_at DESC);
```

### Mapeo con la tabla existente `utpl_registros`

Para que el motor funcione, los registros de `utpl_registros` necesitan dos campos adicionales (o usamos los existentes):

| Campo existente | Uso en el motor |
|-----------------|-----------------|
| `id_negocio` | PK del lead |
| `cedula` | Identificador |
| `telefono1..6` | Lista de teléfonos a iterar |
| `telefono_index` | Índice actual en la lista de teléfonos |
| `intentos_llamada` | Contador global de intentos |
| `win_tries` | Intentos dentro de la ventana actual |
| `win_stamp` | Identificador de ventana actual (`MAÑANA_2026-05-20`) |
| `estado_flujo` | `PENDIENTE` / `EN_PROCESO` / `REINTENTAR` / `FINALIZADO` |
| `fecha_reagenda` | Próxima fecha/hora de marcado |
| `modalidad` | Puede usarse como mapeo a `campaign_slug` |

| Campo nuevo sugerido | Propósito |
|----------------------|-----------|
| `campaign_slug` (TEXT) | Vincular el lead a una campaña del motor |
| `motive_counters` (JSONB) | `{"busy": 2, "voicemail": 1, "no_answer": 0}` — contadores por motivo |

> **Nota**: Si no se quiere modificar `utpl_registros` de inmediato, se puede mapear `modalidad` → `campaign_slug` o crear una tabla de mapeo aparte. Los `motive_counters` pueden vivir en `dialing_attempts_log` consultando agregados.

---

## Fase 1 — Modelo de Datos, Migraciones y Schemas

### Objetivo

Dejar lista la estructura de base de datos en Supabase y los modelos Pydantic/SQLAlchemy en el backend para que todas las fases subsiguientes tengan dónde leer y escribir.

### Desarrollo

1. **Crear proyecto base del backend:**
   ```
   dialing-rules-engine/
   ├── backend/
   │   ├── app/
   │   │   ├── __init__.py
   │   │   ├── main.py
   │   │   ├── config.py
   │   │   ├── db/
   │   │   │   ├── __init__.py
   │   │   │   ├── engine.py       # asyncpg + SQLAlchemy async
   │   │   │   ├── models.py       # Modelos ORM
   │   │   │   └── base.py         # DeclarativeBase
   │   │   └── schemas/
   │   │       ├── __init__.py
   │   │       ├── campaign.py     # Pydantic schemas
   │   │       ├── window.py
   │   │       ├── holiday.py
   │   │       ├── rule.py
   │   │       ├── evaluate.py     # Request/Response de /evaluate
   │   │       └── classify.py     # Request/Response de /classify
   │   ├── alembic/
   │   │   └── versions/
   │   ├── alembic.ini
   │   ├── requirements.txt
   │   └── .env.example
   └── ui/  (vacío en esta fase)
   ```

2. **Ejecutar DDL en Supabase:**
   - Crear tablas `dialing_campaigns`, `dialing_windows`, `dialing_holidays`, `dialing_motive_rules`, `dialing_attempts_log`
   - Crear índices
   - Insertar datos de campaña UTPL como migración de datos inicial (seed)

3. **Modelos SQLAlchemy (async):**
   - `DialingCampaign`, `DialingWindow`, `DialingHoliday`, `DialingMotiveRule`, `DialingAttemptLog`
   - Relaciones: campaign → windows, holidays, rules

4. **Schemas Pydantic:**
   - `CampaignCreate`, `CampaignRead`, `CampaignUpdate`
   - `WindowCreate`, `WindowRead`, `WindowUpdate`
   - `HolidayCreate`, `HolidayRead`
   - `MotiveRuleCreate`, `MotiveRuleRead`, `MotiveRuleUpdate`
   - `EvaluateRequest` (campos del lead + campaign_slug)
   - `EvaluateResponse` (can_call, next_phone, next_action, schedule, counters)
   - `ClassifyRequest` (lead + nomenclatura + ended_reason)
   - `ClassifyResponse` (status_sugerido, estado_flujo, next_action, schedule)

5. **Config (`config.py`):**
   - `SUPABASE_URL`, `SUPABASE_ANON_KEY` (para lectura de registros existentes si fuera necesario)
   - `DATABASE_URL` (PostgreSQL directo con asyncpg: `postgresql+asyncpg://...`)
   - `API_KEY` para autenticación de webhooks desde n8n

6. **Seed inicial — campaña UTPL:**
   - Script que inserta la campaña `utpl-vozia` con sus 3 ventanas (MAÑANA, TARDE, NOCHE), el feriado `2026-05-25`, y las reglas por motivo:
     - `nom_NC` → retry, next_number, 0 min, max_retries=∞
     - `nom_VLL` → retry, same_number, 30 min, max_retries=∞
     - `busy` → retry, same_number, 5 min, max_retries=3
     - `voicemail` → retry, next_number, 15 min, max_retries=2
     - `no_answer` → retry, same_number, 30 min, max_retries=5
     - `failed` → retry, same_number, 10 min, max_retries=3

### Entregable

- [x] Tablas creadas en Supabase con datos semilla para UTPL
- [x] Backend FastAPI corriendo con `uvicorn` (sin endpoints aún, solo health check)
- [x] `alembic upgrade head` ejecutado sin errores
- [x] `.env` configurado con credenciales

### Tests Manuales

| # | Test | Resultado esperado |
|---|------|--------------------|
| 1.1 | `uvicorn app.main:app --reload` | Arranca sin errores |
| 1.2 | `GET /health` | `{"status": "ok", "db": "connected"}` |
| 1.3 | `SELECT * FROM dialing_campaigns WHERE slug='utpl-vozia'` | 1 fila con los datos semilla |
| 1.4 | `SELECT * FROM dialing_windows WHERE campaign_id=...` | 3 filas (MAÑANA, TARDE, NOCHE) |
| 1.5 | `SELECT * FROM dialing_holidays WHERE campaign_id=...` | 1 fila (2026-05-25) |
| 1.6 | `SELECT * FROM dialing_motive_rules WHERE campaign_id=...` | 6 filas |
| 1.7 | `alembic history` | Muestra la migración aplicada |
| 1.8 | `alembic downgrade -1 && alembic upgrade head` | Rollback y re-aplicación sin errores |

---

## Fase 2 — CRUD API Endpoints

### Objetivo

Exponer endpoints REST para crear, leer, actualizar y eliminar campañas, ventanas, feriados y reglas. Servirán de backend tanto para la UI como para administración directa.

### Desarrollo

1. **Endpoints de campañas** (`api/v1/campaigns.py`):
   - `GET /api/v1/campaigns` — listar todas
   - `POST /api/v1/campaigns` — crear
   - `GET /api/v1/campaigns/:id` — obtener una
   - `PUT /api/v1/campaigns/:id` — actualizar
   - `DELETE /api/v1/campaigns/:id` — eliminar (soft? confirmación)

2. **Endpoints de ventanas** (`api/v1/windows.py`):
   - `GET /api/v1/campaigns/:id/windows` — listar ventanas de una campaña
   - `POST /api/v1/campaigns/:id/windows` — agregar ventana
   - `PUT /api/v1/campaigns/:id/windows/:wid` — editar
   - `DELETE /api/v1/campaigns/:id/windows/:wid` — eliminar

3. **Endpoints de feriados** (`api/v1/holidays.py`):
   - `GET /api/v1/campaigns/:id/holidays` — listar
   - `POST /api/v1/campaigns/:id/holidays` — agregar
   - `DELETE /api/v1/campaigns/:id/holidays/:hid` — eliminar

4. **Endpoints de reglas** (`api/v1/rules.py`):
   - `GET /api/v1/campaigns/:id/rules` — listar reglas por motivo
   - `POST /api/v1/campaigns/:id/rules` — agregar regla
   - `PUT /api/v1/campaigns/:id/rules/:rid` — editar regla
   - `DELETE /api/v1/campaigns/:id/rules/:rid` — eliminar
   - `PUT /api/v1/campaigns/:id/rules/reorder` — reordenar reglas

5. **Seguridad básica:**
   - Header `X-API-Key` para endpoints de administración
   - CORS configurado para la UI
   - Rate limiting básico con slowapi

### Entregable

- [x] Swagger UI funcionando en `/docs` con todos los endpoints documentados
- [x] CRUD completo para campañas, ventanas, feriados y reglas
- [x] Validación Pydantic en inputs
- [x] Manejo de errores con códigos HTTP apropiados
- [x] API key protegida

### Tests Manuales

| # | Test | Resultado esperado |
|---|------|--------------------|
| 2.1 | `GET /api/v1/campaigns` | Lista [{"name":"UTPL VozIA","slug":"utpl-vozia",...}] |
| 2.2 | `POST /api/v1/campaigns` body: `{"name":"Test","slug":"test","tz":"America/Bogota"}` | 201 + campaign creada |
| 2.3 | `POST /api/v1/campaigns` body: `{"name":"Dupe","slug":"utpl-vozia"}` | 409 Conflict (slug duplicado) |
| 2.4 | `PUT /api/v1/campaigns/:id` body: `{"max_lifetime_tries":20}` | 200 + campo actualizado |
| 2.5 | `DELETE /api/v1/campaigns/:id` | 204 + cascade borra ventanas, feriados, reglas |
| 2.6 | `GET /api/v1/campaigns/:id/windows` | Lista de 3 ventanas para UTPL |
| 2.7 | `POST /api/v1/campaigns/:id/windows` | 201 + nueva ventana creada |
| 2.8 | Validación: `start_time` > `end_time` | 422 Validation Error |
| 2.9 | `POST /api/v1/campaigns/:id/holidays` | 201 + feriado creado |
| 2.10 | `GET /api/v1/campaigns/:id/rules` | Lista 6 reglas para UTPL |
| 2.11 | `POST /api/v1/campaigns/:id/rules` body: `{"motive":"busy","action":"retry","phone_strategy":"same_number","wait_minutes":5}` | 201 |
| 2.12 | `POST` regla con `motive` duplicado en misma campaña | 409 Conflict |
| 2.13 | `POST` regla con `action` inválido | 422 |
| 2.14 | Request sin `X-API-Key` | 401 Unauthorized |
| 2.15 | `GET /docs` | Swagger UI carga y muestra todos los endpoints |

---

## Fase 3 — Motor de Evaluación

### Objetivo

Implementar la lógica central: dado un lead y una campaña, determinar si se puede llamar, a qué número, con qué reglas aplicar, y si no se puede, cuándo reintentar.

### Desarrollo

1. **Módulo `engine/time.py` — Evaluación temporal:**
   - `get_current_time(campaign)` → ahora en TZ de la campaña
   - `is_sunday(dow)` → bool
   - `is_holiday(today, campaign_id)` → bool (consulta DB)
   - `get_today_windows(campaign_id, dow)` → ventanas activas hoy
   - `find_current_window(now_time, windows)` → ventana actual o None
   - `find_upcoming_window(now_time, windows)` → próxima ventana o None
   - `calculate_next_valid_time(now, campaign)` → si hoy no se puede, cuándo sí

2. **Módulo `engine/phone.py` — Estrategias de número:**
   - `select_phone(phones[], strategy)` → número según estrategia
   - `get_phones_from_lead(lead, cc)` → lista de teléfonos parseados en E.164
   - Estrategias:
     - `same_number`: usar `phones[current_index % len]`
     - `next_number`: avanzar índice y usar el siguiente
     - `same_index`: mantener índice (sin incrementar)
     - `next_index`: incrementar índice para la próxima iteración

3. **Módulo `engine/rules.py` — Evaluación de reglas por motivo:**
   - `get_rule_for_motive(campaign_id, motive)` → regla de la DB
   - `get_motive_counters(lead, campaign_id)` → contadores por motivo
   - `evaluate_rule(rule, counters, max_lifetime)` → acción resultante
   - Lógica de escalamiento: si `counters[motive] >= rule.max_retries`, escalar a la siguiente acción (configurable o hardcodeado: retry → next_number → finalize)

4. **Módulo `engine/core.py` — Orquestador:**
   - `evaluate_lead(lead, campaign_slug)` → `EvaluateResponse`
     - Determinar TZ y ventanas
     - Verificar feriados/domingo → reprogramar
     - Verificar intentos totales → AGOTADO
     - Verificar ventana actual → si fuera de horario, reprogramar
     - Verificar límite de ventana (win_tries vs max_window_tries)
     - Si puede llamar, seleccionar teléfono según estrategia vigente
   - `classify_result(lead, campaign_slug, motive_code, ended_reason)` → `ClassifyResponse`
     - Buscar regla por `motive_code` o `ended_reason`
     - Aplicar acción: retry (cuándo), finalize, escalate
     - Aplicar estrategia de número
     - Devolver nuevo `estado_flujo`, `fecha_reagenda`, `telefono_index`

5. **Endpoints del motor (`api/v1/evaluate.py` y `api/v1/classify.py`):**
   - `POST /api/v1/evaluate` — para el flujo de llamadas (antes de marcar)
   - `POST /api/v1/classify` — para el flujo de cierre (después de la llamada)

### Esquema de Request/Response

```python
# POST /api/v1/evaluate
class EvaluateRequest(BaseModel):
    campaign_slug: str
    lead: LeadData

class LeadData(BaseModel):
    id_negocio: str
    cedula: str
    intentos_llamada: int = 0
    telefono_index: int = 0
    win_tries: int = 0
    win_stamp: str | None = None
    estado_flujo: str = "PENDIENTE"
    fecha_reagenda: str | None = None
    phones: list[str] = []             # En E.164

class EvaluateResponse(BaseModel):
    can_call: bool
    phone_to_call: str | None          # Número E.164 a marcar
    phone_index: int                    # Índice actualizado
    win_tries: int                      # Intentos en ventana actualizados
    win_stamp: str | None               # Stamp de ventana
    estado_flujo: str                   # PENDIENTE / EN_PROCESO / REINTENTAR / FINALIZADO
    next_schedule: str | None           # ISO datetime si hay que reprogramar
    motive_rules_applied: list[str]     # Reglas que se aplicaron (para debug)
    reason: str                         # Explicación legible

# POST /api/v1/classify
class ClassifyRequest(BaseModel):
    campaign_slug: str
    lead: LeadData
    nomenclatura: str | None            # NC, VLL, NUE, ACE, etc.
    ended_reason: str | None            # busy, voicemail, no_answer, etc.
    phone_used: str | None              # Número que se usó en la llamada

class ClassifyResponse(BaseModel):
    estado_flujo: str                   # REINTENTAR o FINALIZADO
    status_sugerido: str                # REINTENTAR, FINAL, AGOTADO, ESCALADO
    phone_index: int                    # Nuevo índice de teléfono
    next_schedule: str | None           # Cuándo reintentar
    wait_minutes: int                   # Minutos de espera aplicados
    motive: str                         # Motivo que disparó la regla
    action: str                         # Acción ejecutada
    phone_strategy: str                 # Estrategia aplicada
```

### Lógica del Motor — Flujo Detallado

```
                    ┌──────────────────┐
                    │  POST /evaluate   │
                    └────────┬─────────┘
                             │
                    ┌────────▼─────────┐
                    │ ¿Domingo?         │──Sí──► reprogramar Lunes 8am
                    └────────┬─────────┘
                             │No
                    ┌────────▼─────────┐
                    │ ¿Feriado?         │──Sí──► reprogramar día siguiente 8am
                    └────────┬─────────┘
                             │No
                    ┌────────▼─────────┐
                    │ ¿intentos >= max? │──Sí──► FINALIZADO (AGOTADO)
                    └────────┬─────────┘
                             │No
                    ┌────────▼─────────┐
                    │ ¿Hay ventanas hoy?│──No──► reprogramar próximo día hábil
                    └────────┬─────────┘
                             │Sí
                    ┌────────▼─────────┐
                    │ ¿En ventana actual?│──No──► reprogramar próxima ventana
                    └────────┬─────────┘
                             │Sí
                    ┌────────▼─────────┐
                    │ ¿win_tries < max?│──No──► reprogramar próxima ventana
                    └────────┬─────────┘
                             │Sí
                    ┌────────▼─────────┐
                    │ Seleccionar tel   │
                    │ según estrategia  │
                    └────────┬─────────┘
                             │
                    ┌────────▼─────────┐
                    │ Evaluar motivos   │
                    │ previos del lead   │
                    └────────┬─────────┘
                             │
                    ┌────────▼─────────┐
                    │ can_call = true   │
                    │ phone = selec.    │
                    └──────────────────┘


                    ┌──────────────────┐
                    │  POST /classify   │
                    └────────┬─────────┘
                             │
                    ┌────────▼─────────┐
                    │ Buscar regla por  │
                    │ motivo o nom_code │
                    └────────┬─────────┘
                             │
                    ┌────────▼─────────┐
                    │ ¿Acción = retry?  │
                    └────┬─────────┬───┘
                         │No       │Sí
                         ▼         ▼
                    FINALIZADO  ┌──────────────────┐
                                │ Aplicar estrategia│
                                │ de número         │
                                └────────┬─────────┘
                                         │
                                ┌────────▼─────────┐
                                │ Calcular          │
                                │ next_schedule =   │
                                │ now + wait_min    │
                                └────────┬─────────┘
                                         │
                                ┌────────▼─────────┐
                                │ Verificar que     │
                                │ next_schedule     │
                                │ esté en ventana   │
                                └────────┬─────────┘
                                         │
                                ┌────────▼─────────┐
                                │ estado_flujo =    │
                                │ REINTENTAR        │
                                └──────────────────┘
```

### Entregable

- [x] `POST /api/v1/evaluate` funcional
- [x] `POST /api/v1/classify` funcional
- [x] Lógica de ventanas, feriados, domingos
- [x] Lógica de límites de intentos (vida y ventana)
- [x] Estrategias de selección de número
- [x] Reglas por motivo evaluadas correctamente
- [x] Registro en `dialing_attempts_log` en cada `classify`

### Tests Manuales

| # | Test | Input | Resultado esperado |
|---|------|-------|--------------------|
| 3.1 | `POST /evaluate` lead con intentos < max, en ventana MAÑANA | lead normal, campaign_slug=utpl-vozia | `can_call=true`, `phone_to_call` no vacío |
| 3.2 | Idem pero win_tries = 3 | win_tries=3 en MAÑANA | `can_call=false`, `next_schedule` = inicio TARDE |
| 3.3 | `POST /evaluate` fuera de horario (02:00) | now simulado a las 02:00 | `can_call=false`, `next_schedule` = 08:00 hoy |
| 3.4 | `POST /evaluate` en domingo | now simulado domingo | `can_call=false`, `next_schedule` = lunes 8am |
| 3.5 | `POST /evaluate` en feriado (2026-05-25) | now simulado 2026-05-25 | `can_call=false`, `next_schedule` = 2026-05-26 8am |
| 3.6 | `POST /evaluate` intentos >= 16 | intentos_llamada=16 | `can_call=false`, `estado_flujo=FINALIZADO`, reason="AGOTADO" |
| 3.7 | `POST /evaluate` lead sin teléfonos | phones=[] | `can_call=false`, razón "sin teléfonos" |
| 3.8 | `POST /classify` motivo=busy, regla=retry/same/5min | nomenclatura=NC, ended_reason=busy | `estado_flujo=REINTENTAR`, `next_schedule` = now+5min, mismo índice |
| 3.9 | `POST /classify` motivo=voicemail, regla=retry/next/15min | ended_reason=voicemail | `estado_flujo=REINTENTAR`, `next_schedule` = now+15min, índice+1 |
| 3.10 | `POST /classify` motivo=busy, 4ta vez (max_retries=3) | busy counter=3 | `action=escalate` o `action=finalize` según config |
| 3.11 | `POST /classify` nomenclatura=NUE (no reintentable) | nom_code=NUE | `estado_flujo=FINALIZADO`, `status_sugerido=FINAL` |
| 3.12 | `POST /classify` nomenclatura=IND | nom_code=IND | `estado_flujo=FINALIZADO` |
| 3.13 | `POST /evaluate` con campaign_slug inexistente | slug=no-existe | 404 |
| 3.14 | `POST /evaluate` sin API key | sin header | 401 |
| 3.15 | Verificar `dialing_attempts_log` después de classify | — | 1 fila insertada con datos correctos |

---

## Fase 4 — UI de Administración

### Objetivo

Crear una interfaz web con React + shadcn/ui + Tailwind que permita gestionar campañas, ventanas, feriados y reglas de marcado de forma visual e intuitiva.

### Desarrollo

1. **Inicializar proyecto React con Vite:**
   ```bash
   npm create vite@latest ui -- --template react-ts
   cd ui
   npx shadcn@latest init
   ```

2. **Componentes shadcn necesarios:**
   - `Button`, `Input`, `Select`, `Switch`, `Dialog`, `Table`
   - `Card`, `Tabs`, `Badge`, `Separator`
   - `Form` + `react-hook-form` + `zod`
   - `Toast` (sonner) para notificaciones
   - `AlertDialog` para confirmaciones de eliminación

3. **Páginas/Vistas:**

   ```
   /                          → Dashboard (lista de campañas)
   /campaigns/new             → Formulario crear campaña
   /campaigns/:id             → Detalle campaña (tabs: General, Ventanas, Feriados, Reglas)
   /campaigns/:id/windows     → Gestión de ventanas (tabla + modal crear/editar)
   /campaigns/:id/holidays    → Gestión de feriados (calendario + tabla)
   /campaigns/:id/rules       → Editor de reglas (tarjetas drag-and-drop)
   ```

4. **Editor de Reglas (componente principal):**

   Cada regla se muestra como una tarjeta con:

   ```
   ┌─────────────────────────────────────────────────────┐
   │  Regla #1                                    [⇅] [✕]│
   │                                                      │
   │  Cuando          [  busy  ▼  ]                       │
   │  ─────────────────────────────────────────────────   │
   │  Acción          [  retry  ▼  ]                       │
   │  Teléfono        [  same_number  ▼  ]                 │
   │  Esperar         [  5  ] minutos                      │
   │  Máx intentos    [  3  ]                              │
   │                                                      │
   │  [Activo ▣]                                          │
   └─────────────────────────────────────────────────────┘
   ```

   - Drag & drop para reordenar prioridad
   - Modal o inline para crear/editar
   - Selects predefinidos: motive, action, phone_strategy

5. **Vista de Ventanas:**

   Tabla con columnas: Nombre | Días | Inicio | Fin | Orden | Acciones
   
   - Modal para crear/editar con checkboxes para días (L M X J V S D)
   - Validación: inicio < fin, al menos 1 día

6. **Vista de Feriados:**

   - Grid de fechas + botón "Agregar feriado"
   - DatePicker para seleccionar fecha
   - Opcional: descripción

7. **Cliente HTTP:**
   - `fetch` nativo o `ky` para llamadas al backend
   - Interceptor para `X-API-Key`
   - Tipos TypeScript generados de los schemas Pydantic (o manuales)

8. **Estados:**
   - Loading skeletons (shadcn Skeleton)
   - Error states con retry
   - Empty states ("No hay reglas definidas. Crea la primera.")
   - Confirmación al eliminar

### Entregable

- [x] UI funcional corriendo en `http://localhost:5173`
- [x] CRUD completo de campañas desde la UI
- [x] CRUD de ventanas con visualización clara de horarios
- [x] CRUD de feriados con selector de fecha
- [x] Editor de reglas con drag & drop para reordenar
- [x] Validaciones de formulario (zod)
- [x] Toasts de éxito/error en cada acción
- [x] Responsive design (funciona en desktop y tablet)

### Tests Manuales

| # | Test | Resultado esperado |
|---|------|--------------------|
| 4.1 | Abrir UI → lista de campañas | Muestra "UTPL VozIA" y botón "Nueva Campaña" |
| 4.2 | Crear campaña desde UI | Form → submit → aparece en lista → toast "Campaña creada" |
| 4.3 | Editar campaña | Click editar → modal → cambiar campo → guardar → reflejado |
| 4.4 | Eliminar campaña | Click eliminar → confirm dialog → desaparece → toast |
| 4.5 | Ver ventanas de UTPL | 3 filas: MAÑANA (L-V 08-12), TARDE (L-V 12:01-14), NOCHE (L-V 14:01-20) |
| 4.6 | Agregar ventana SABADOS 09-13 | 4ta fila aparece, ordenada |
| 4.7 | Editar ventana: cambiar fin | Modal → cambiar hora → guardar → reflejado |
| 4.8 | Eliminar ventana | Confirm → desaparece |
| 4.9 | Ver feriados | Muestra 2026-05-25 |
| 4.10 | Agregar feriado | DatePicker → seleccionar → aparece en tabla |
| 4.11 | Eliminar feriado | Confirm → desaparece |
| 4.12 | Ver reglas UTPL | 6 tarjetas con motivos predefinidos |
| 4.13 | Crear nueva regla | Form → submit → aparece tarjeta nueva |
| 4.14 | Editar regla: cambiar wait_minutes | Click tarjeta → modal → cambiar → guardar |
| 4.15 | Eliminar regla | Confirm → tarjeta desaparece |
| 4.16 | Reordenar reglas (drag) | Arrastrar tarjeta → nueva posición → refrescar → orden persistido |
| 4.17 | Toggle active/inactive en regla | Switch → regla se desactiva (visible pero atenuada) |
| 4.18 | Form validation: motivo vacío | Error "El motivo es requerido" |
| 4.19 | Form validation: wait_minutes negativo | Error "Debe ser >= 0" |
| 4.20 | Probar sin API key | Requests fallan con 401 → UI muestra error |
| 4.21 | Probar con backend caído | UI muestra estado de error con botón "Reintentar" |

---

## Fase 5 — Integración con n8n

### Objetivo

Modificar los flujos existentes `Utpl_Llamadas.json` y `Utpl_CierreLlamadas.json` para que deleguen la lógica de reglas al nuevo motor, con mínimo riesgo de regresión.

### Desarrollo

1. **Modificar `UTPL_LLAMADAS` para /evaluate:**

   **Antes** (3 nodos):
   ```
   NORMALIZA DATOS → POLITICAS REGLA 3x3 → SI PUEDE LLAMAR → PROCESA TELEFONOS
   ```

   **Después** (1 nodo HTTP Request):
   ```
   NORMALIZA DATOS → HTTP POST /api/v1/evaluate → SI PUEDE LLAMAR
   ```

   - El nodo `POLITICAS REGLA 3x3` y `PROCESA TELEFONOS` se reemplazan por un solo HTTP Request
   - La respuesta del motor ya incluye `can_call`, `phone_to_call`, `phone_index`, `win_tries`, etc.
   - `SI PUEDE LLAMAR` evalúa `$json.can_call` en lugar de `$json.puedeLlamar`
   - Los campos `telefono_actual`, `phones_parsed`, etc. vienen del motor

2. **Modificar `UTPL_CIERRE_LLAMADAS` para /classify:**

   **Antes**:
   ```
   EXTRAE STRUCTURED OUTPUTS → CLASIFICA ESTADO CIERRE
   ```

   **Después**:
   ```
   EXTRAE STRUCTURED OUTPUTS → HTTP POST /api/v1/classify
   ```

   - `CLASIFICA ESTADO CIERRE` se reemplaza por HTTP Request al motor
   - La respuesta incluye `estado_flujo`, `status_sugerido`, `phone_index` actualizado
   - Los campos de `MAPEA CAMPOS` toman los valores del motor

3. **Ajustes en la configuración inicial:**

   Agregar al `CONFIG INICIAL`:
   ```javascript
   dialingEngine: {
     baseUrl: 'https://api.tudominio.com',
     apiKey: 'tu-api-key',
     campaignSlug: 'utpl-vozia'
   }
   ```

4. **Contrato de datos estándar entre n8n y el motor:**

   Cada flujo n8n es responsable de normalizar los campos de su tabla de registros al formato estándar del motor antes de llamar `/evaluate` o `/classify`. El motor espera siempre la misma estructura JSON, sin importar de qué tabla vengan los datos.

   *Ejemplo — mapeo en Code node de n8n para un proyecto nuevo:*

   ```javascript
   // Solidario: tabla solidario_registros usa phone_1, phone_2 en vez de telefono1, telefono2
   const lead = {
     id_negocio: $json.id_registro,          // campo con otro nombre
     cedula: $json.cedula,
     intentos_llamada: $json.reintentos,     // campo con otro nombre
     telefono_index: $json.phone_idx || 0,   // campo con otro nombre
     win_tries: $json.win_tries || 0,
     win_stamp: $json.win_stamp,
     estado_flujo: $json.status,             // campo con otro nombre
     fecha_reagenda: $json.next_call,
     phones: [$json.phone_1, $json.phone_2, $json.phone_3]
   };
   ```

   Solo cambian el Code node de normalización y el `campaign_slug`. El motor no se entera.

5. **Manejo de fallback:**

   Si el motor no responde:
   - `/evaluate`: usar lógica vieja hardcodeada como fallback (mantener código existente comentado)
   - `/classify`: igual, fallback a lógica vieja
   - Loggear el error para monitoreo

6. **Variables de n8n modificadas:**

   El nodo HTTP Request debe mapear:

   **Request a /evaluate:**
   ```json
   {
     "campaign_slug": "utpl-vozia",
     "lead": {
       "id_negocio": "{{ $json.id_negocio }}",
       "cedula": "{{ $json.cedula }}",
       "intentos_llamada": "{{ $json.intentos_llamada }}",
       "telefono_index": "{{ $json.telefono_index }}",
       "win_tries": "{{ $json.win_tries }}",
       "win_stamp": "{{ $json.win_stamp }}",
       "estado_flujo": "{{ $json.estado_flujo }}",
       "fecha_reagenda": "{{ $json.fecha_reagenda }}",
       "phones": ["{{ $json.telefono1 }}", "{{ $json.telefono2 }}", ...]
     }
   }
   ```

   **Request a /classify:**
   ```json
   {
     "campaign_slug": "utpl-vozia",
     "lead": { ... },
     "nomenclatura": "{{ $json.nomenclatura }}",
     "ended_reason": "{{ $json.endedReason }}",
     "phone_used": "{{ $json.telefono_actual }}"
   }
   ```

### Entregable

- [x] Nuevas versiones de `Utpl_Llamadas.json` y `Utpl_CierreLlamadas.json` con HTTP Requests al motor
- [x] Flujos viejos respaldados (archivados como `.bak`)
- [x] Lógica de fallback funcionando
- [x] Variables de n8n actualizadas para incluir `dialingEngine`

### Tests Manuales

| # | Test | Resultado esperado |
|---|------|--------------------|
| 5.1 | Ejecutar `UTPL_LLAMADAS` con motor online | Flujo llega a `LLAMAR VAPI AGENTE` con teléfono correcto |
| 5.2 | Ejecutar `UTPL_LLAMADAS` con motor offline | Flujo usa fallback (lógica vieja) → no se rompe |
| 5.3 | `UTPL_CIERRE_LLAMADAS` recibe webhook Vapi → clasifica con motor | `estado_flujo` y `fecha_reagenda` correctos |
| 5.4 | Idem con motor offline | Usa fallback → clasificación correcta |
| 5.5 | Verificar que `telefono_index` se actualiza correctamente | Índice avanza según regla (mismo o siguiente) |
| 5.6 | Verificar `win_tries` después de classify | Refleja contador actualizado |
| 5.7 | Verificar `fecha_reagenda` para retry con 5min | now + 5min en ISO |
| 5.8 | Prueba end-to-end: lead nuevo → evaluate → llamar → classify | Ciclo completo sin errores |
| 5.9 | Prueba con feriado (simulado) | Reprograma correctamente |
| 5.10 | Prueba con domingo | Reprograma a lunes 8am |

---

## Fase 6 — Pruebas, Migración y Puesta en Marcha

### Objetivo

Validar el sistema completo en paralelo con el actual, migrar UTPL definitivamente, y dejar documentación para el equipo.

### Desarrollo

1. **Pruebas en paralelo:**
   - Crear una campaña de test (`test-campaign`) que use el motor pero no afecte leads reales
   - Correr el flujo de test durante 1 día verificando logs
   - Comparar decisiones del motor vs lógica vieja (deben ser idénticas para UTPL)

2. **Script de comparación A/B:**
   - Para N leads, ejecutar lógica vieja y nueva en paralelo
   - Comparar: `can_call`, `phone_selected`, `next_schedule`
   - Reportar discrepancias

3. **Migración definitiva:**
   - Activar `campaign_slug = 'utpl-vozia'` en los leads o mapear por `modalidad`
   - Actualizar flujos n8n a las versiones nuevas
   - Activar schedule y monitorear primeras 24 horas

4. **Documentación:**
   - `README.md` del módulo
   - `DEPLOY.md` con pasos de despliegue
   - `API.md` con documentación de endpoints (Swagger ya cubre)
   - Actualizar `AGENTS.md` con nueva arquitectura

5. **Despliegue en servidor:**
   - Opción A: mismo servidor que n8n (`n8nps.plusservices.ec`)
   - Opción B: Railway.app (gratuito para pruebas)
   - Systemd service o Docker Compose
   - Health check endpoint para monitoreo

6. **Monitoreo:**
   - Health check: `GET /health`
   - Métricas básicas: contador de evaluaciones, errores
   - Logs estructurados (JSON)

### Entregable

- [x] Campaña UTPL migrada al motor
- [x] Flujos n8n actualizados y funcionando en producción
- [x] Documentación completa
- [x] Despliegue en servidor con health check
- [x] Plan de rollback documentado

### Tests Manuales

| # | Test | Resultado esperado |
|---|------|--------------------|
| 6.1 | Ejecutar script A/B con 100 leads | 0 discrepancias críticas |
| 6.2 | Campaña test → ciclo de llamadas completo | Sin errores |
| 6.3 | UTPL producción → primeras 10 llamadas con motor | Comportamiento idéntico al viejo |
| 6.4 | UI → modificar regla (ej: cambiar wait de 5 a 10 min) | Siguiente classify usa 10 min |
| 6.5 | UI → agregar feriado | Siguiente evaluate reprograma ese día |
| 6.6 | Rollback: desactivar motor, volver a flujos viejos | Sistema funciona como antes |
| 6.7 | Health check `/health` | `{"status":"ok","db":"connected"}` |
| 6.8 | Health check con DB caída | `{"status":"degraded","db":"disconnected"}` |
| 6.9 | Cargar 1000 evaluaciones simultáneas | Sin timeouts, respuestas < 500ms |
| 6.10 | Logs: verificar que errores se registran con contexto | Traza completa en logs |

---

## 9. Riesgos y Mitigaciones

| Riesgo | Probabilidad | Impacto | Mitigación |
|--------|-------------|---------|------------|
| **El motor decide distinto que la lógica vieja** | Media | Alto | Script A/B antes de migrar. Fallback a lógica vieja si hay discrepancia. |
| **Latencia de red entre n8n y el motor** | Baja | Medio | Timeout de 5s en HTTP Request. Usar fallback local si no responde. |
| **Error humano en UI (borrar regla crítica)** | Media | Alto | AlertDialog de confirmación. Seed de reglas por defecto. Botón "Restaurar defaults". |
| **Supabase caído** | Baja | Alto | Fallback a lógica hardcodeada vieja en n8n. |
| **Cambios en schema de `utpl_registros` que rompen el motor** | Baja | Medio | El motor solo lee campos específicos. Validación estricta de tipos. |
| **Seguridad: API expuesta sin protección** | Media | Alto | API Key en header. CORS restrictivo. Rate limiting. |
| **Migración deja registros inconsistentes** | Media | Alto | Migración gradual: 10% → 50% → 100%. Rollback instantáneo. |
| **Múltiples clientes/campañas colisionan** | Baja | Bajo | Slug único por campaña. Aislamiento total por `campaign_id`. |

---

## 10. Stack Tecnológico Final

| Componente | Tecnología | Versión |
|------------|-----------|---------|
| Backend | Python 3.12 + FastAPI | latest |
| ORM | SQLAlchemy 2.0 (async) | 2.0+ |
| DB Driver | asyncpg | 0.29+ |
| Validación | Pydantic v2 | 2.5+ |
| Migraciones | Alembic | 1.13+ |
| Servidor | Uvicorn | 0.29+ |
| Base de datos | Supabase PostgreSQL 15 | managed |
| UI Framework | React 18 + TypeScript | 18+ |
| Build tool | Vite | 5+ |
| Componentes | shadcn/ui (Radix + Tailwind) | latest |
| Formularios | react-hook-form + zod | latest |
| Estilos | Tailwind CSS 3.4 | 3.4+ |
| Despliegue | Docker + systemd | latest |
| Monitoreo | Health check endpoint | nativo |

---

## Resumen de Tiempos

| Fase | Días estimados | Depende de |
|------|---------------|------------|
| 1. Modelo de Datos | 1 | — |
| 2. CRUD API | 2 | Fase 1 |
| 3. Motor de Evaluación | 2 | Fase 1 |
| 4. UI de Administración | 3 | Fase 2 |
| 5. Integración n8n | 1 | Fase 3 |
| 6. Pruebas y Migración | 1 | Fase 4, 5 |
| **Total** | **10 días** | |

---

## Próximos Pasos

1. Revisar este plan y aprobar o ajustar
2. Crear el proyecto con `backend/` y `ui/`
3. Ejecutar Fase 1 (crear tablas en Supabase + seed UTPL)
4. Continuar con Fases 2-6 según cronograma

---

*Documento generado el 2026-05-20. Sujeto a ajustes durante el desarrollo.*
