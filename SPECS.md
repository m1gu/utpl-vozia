# UTPL VozIA - Especificacion Tecnica (SPECS.md)

## 1. Arquitectura del Sistema

### 1.1 Diagrama de Integracion

```
┌──────────┐     ┌──────────────────┐     ┌──────────────┐
│  ALTIVA  │────►│  n8n (orquestador)│────►│   Supabase   │
│ (origen) │     │ n8nps.plusservices│     │ (base datos) │
└──────────┘     └────────┬─────────┘     └──────────────┘
                          │
                    ┌─────┴─────┐    ┌───────────────┐
                    │  Vapi AI  │    │  CRM de UTPL  │
                    │ (llamadas)│    │  (SOAP 1.1)   │
                    └───────────┘    └───────────────┘
```

**Sistema bidirectional:**
- **IN**: ALTIVA → n8n → Supabase (registro de leads)
- **OUT**: n8n → CRM de UTPL vía SOAP `RegistrarLLamada` (notificacion de resultado final)

### 1.2 Ciclo de Vida de un Registro

```
1. CRM externo envia datos ──► INGRESO_LEAD ──► INSERT/UPDATE utpl_registros (estado_flujo=PENDIENTE)
2. Schedule (20s) ──► BUSCA Y BLOQUEA ──► POLITICAS 3x3 ──► LLAMAR VAPI
3. Vapi finaliza llamada ──► webhook CIERRE ──► ACTUALIZA REGISTRO + INSERT utpl_llamadas
4. Si id_nomenclatura = NIN → keyword match → SOAP XML → ENVIA A CRM UTPL
5. Si intentos_llamada >= 16 (AGOTADO) → ENVIA A CRM UTPL (NIN - No Localizable)
```

---

## 2. Tablas de Base de Datos

### 2.1 utpl_registros (Registro Maestro)

| Columna | Tipo | Descripcion |
|---------|------|-------------|
| `id_negocio` | VARCHAR(100) PK | Identificador unico del negocio/lead |
| `id_interno_negocio` | TEXT | ID interno del lead en el CRM externo (dealid para SOAP) |
| `cedula` | VARCHAR(20) | Identificacion del estudiante (texto para preservar ceros) |
| `nombre` | VARCHAR(255) | Primer nombre |
| `apellido` | VARCHAR(255) | Apellidos |
| `producto` | VARCHAR(255) | Nombre de la carrera (ej: "Marketing") |
| `modalidad` | VARCHAR(50) | MODALIDAD EN LINEA, POSGRADO, TECNOLÓGICO |
| `nombre_corto_campania` | TEXT | Nombre corto de la campania en Altiva (para notificacion de nodo) |
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
- `chk_modalidad`: modalidad IN ('MODALIDAD EN LINEA', 'POSGRADO', 'TECNOLÓGICO')
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

### 2.3 utpl_crm (Auditoria de Envios SOAP al CRM)

Registra cada peticion enviada al web service `RegistrarLLamada` del CRM de UTPL y su respuesta.

| Columna | Tipo | Descripcion |
|---------|------|-------------|
| `id` | BIGSERIAL PK | ID autoincremental |
| `id_negocio` | TEXT NOT NULL | ID del lead |
| `flujo_origen` | TEXT NOT NULL | 'CierreLlamadas' o 'Llamadas' |
| `nomenclatura` | TEXT | Nomenclatura de la gestion (NIN, NC) |
| `dealstage` | TEXT | ID del embudo (1020923926 NIN, 1008735099 NC) |
| `hs_call_disposition` | TEXT | UUID del sub-motivo CRM |
| `sales_stage_detail` | TEXT | Nombre del subestado (ej: "NIN - Equivocado") |
| `agent_name` | TEXT | Nombre del agente (ARIA UTPL) |
| `hs_call_duration` | TEXT | Duracion en segundos |
| `hs_call_body` | TEXT | Comentario/resumen de la gestion |
| `commitment_date` | TEXT | Fecha de compromiso |
| `dealid` | TEXT | ID interno del negocio (id_interno_negocio) |
| `hs_timestamp` | TEXT | Fecha y hora de la gestion |
| `scheduling_date` | TEXT | Fecha de agenda |
| `soap_xml` | TEXT | XML SOAP completo enviado |
| `http_code` | TEXT | Codigo HTTP de respuesta (201 = exito) |
| `id_return` | TEXT | ID retornado por el CRM |
| `error_messages` | TEXT | Mensajes de error concatenados (messagews1|2|3) |
| `created_at` | TIMESTAMPTZ DEFAULT NOW() | Fecha de creacion |

**Indices:**
- `idx_utpl_crm_id_negocio` ON id_negocio
- `idx_utpl_crm_created_at` ON created_at

### 2.4 utpl_config (Configuracion Global)

Almacena tokens, credenciales y parametros del sistema.

| Columna | Tipo | Descripcion |
|---------|------|-------------|
| `key` | TEXT PK | Clave unica |
| `value` | TEXT | Valor |
| `expires_at` | TIMESTAMPTZ | Fecha de expiracion (para tokens) |
| `updated_at` | TIMESTAMPTZ DEFAULT NOW() | Fecha de actualizacion |

**Registros tipicos:**
| key | value | expires_at |
|-----|-------|-----------|
| `altiva_token` | `eyJhbGciOi...` | timestamp de expiracion |
| `client_id` | `7` | null |
| `client_secret` | `ug7wMEST...` | null |

---

## 3. Flujos n8n - Especificacion Detallada

### 3.1 Flujo: INGRESO LEAD

**Archivo:** `UTPL_INGRESO_LEAD.json`
**Trigger:** Webhook `POST /utpl-ingreso-lead`

#### Estructura:
```
Webhook Ingreso Lead
  └─ VALIDA API AUTH (IF: x-api-auth header)
       ├─ OK → NORMALIZA Y MAPEA LEAD (Code node)
       │        └─ GUARDA LEAD EN UTPL REGISTROS (Postgres upsert)
       │             └─ RESPUESTA 200 OK
       └─ FAIL → RESPUESTA 401
```

#### Mapping CRM externo → utpl_registros:
| CRM Field | DB Column |
|-----------|-----------|
| `id_negocio` | `id_negocio` |
| `id_interno_negocio` | `id_interno_negocio` |
| `id_persona` | `cedula` |
| `nombres_completos_persona` | `nombre` + `apellido` (split automático) |
| `nombre_campania` | `modalidad` (derivado por reglas de campaña) |
| `nombre_corto_campania` | `nombre_corto_campania` |
| `nombre_producto_interes` | `producto` |
| `celular_persona` | `telefono1` |
| `tipo_solicitud` | `tipo_solicitud` (finiquitar → fuerza FINALIZADO) |

#### Auth:
- Header: `x-api-auth`
- Token: `utpl-93d6061217323b4ee8c999d670bb506437ffd3d3aa1d3510`

#### Upsert Logic:
- **Matching column:** `id_negocio`
- **INSERT (nuevo):** Campos de datos + `estado_flujo = 'PENDIENTE'`
- **UPDATE (existente):** Solo campos de datos (nombre, apellido, modalidad, producto, telefono1). NO toca estado_flujo ni operativos.

### 3.2 Flujo: UTPL Llamadas

**Archivo:** `Utpl_Llamadas.json`
**Trigger:** Schedule Trigger (cada 20 segundos)

#### Config (CONFIG INICIAL UTPL):
```javascript
cfg = {
  runtime: { testMode: false, timeOffsetMinutes: 0 },
  db: { schema: 'public', table: 'utpl_registros', pk: 'id_negocio' },
  states: { pending: 'PENDIENTE', inProgress: 'EN_PROCESO', retry: 'REINTENTAR', done: 'FINALIZADO' },
  agents: {
    'MODALIDAD EN LINEA': 'cc4bbac0-0736-48f6-8175-0bfe4c4e8a76',
    'POSGRADO': 'd61d17dc-6e48-4ce7-bfdb-3dc40dcd329e',
    'TECNOLÓGICO': '638fb59f-0522-4d76-9ca4-a47609f64961'
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
  noPhoneClassification: { nomenclatura: 'NC', codigo_respuesta: 'NO_CONTACTO', motivo: 'Sin numero de telefono valido' },
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
}
```

#### Nodos (23 nodos):
1. **EJECUTA ESTO CADA 20 SEG** - Schedule trigger
2. **CONFIG INICIAL UTPL** - Code node con toda la configuracion
3. **BUSCA Y BLOQUEA REGISTRO** - PostgreSQL `SELECT ... FOR UPDATE SKIP LOCKED`
4. **SI SE ENCONTRO REGISTRO** - IF: `$json.id_negocio exists`
5. **NORMALIZA DATOS** - Limpia y estandariza campos
6. **POLITICAS REGLA 3x3** - Aplica regla de ventanas y selecciona asistente
7. **SI PUEDE LLAMAR** - IF: `$json.puedeLlamar === true`
8. **PROCESA TELEFONOS** - Formatea a E.164, selecciona por telefono_index
9. **FORMATEA STATUS** - Set node para cuando no se puede llamar
10. **GUARDA STATUS** - Upsert estado y fecha_reagenda
11. **SI FINAL AGOTADO** - IF: `$json.status_sugerido === 'AGOTADO'` → CRM
12. **PREPARA SOAP XML AGOTADO** - SOAP XML con NIN-No Localizable
13. **ENVIA A CRM UTPL** - HTTP POST al web service SOAP
14. **PROCESA RESPUESTA CRM UTPL** - Parse XML response + genera INSERT query
15. **INSERTA EN CRM UTPL** - Guarda auditoria en tabla utpl_crm
16. **SI QUEDAN NUMEROS** - IF: `$json.isOutOfNumbers === false`
17. **CAPTURA SNAPSHOT** - Guarda estado previo para fallback
18. **SIN NUMERO VALIDO** - Marca FINALIZADO si no hay telefonos
19. **GUARDA PRE-LLAMADA** - Incrementa contadores antes de llamar
20. **GUARDA REPORTE** - Upsert cuando no hay numero
21. **LLAMAR VAPI AGENTE** - HTTP POST a Vapi API
22. **FALLBACK RESTORE** - Restaura snapshot si falla
23. **NO HACE NADA** - Nodo terminal

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
  "metadata": { "id_negocio": "...", "cedula": "...", "modalidad": "...", "producto": "...", "nombre_corto_campania": "..." },
  "assistantOverrides": {
    "variableValues": {
      "sip": "0", "cedula": "...", "nombre": "...", "nombre_cliente": "...",
      "producto": "...", "modalidad": "...", "modo": "normal", "MODO": "normal"
    }
  }
}
```

### 3.3 Flujo: CIERRE LLAMADAS UTPL

**Archivo:** `Utpl_CierreLlamadas.json`
**Trigger:** Webhook `POST /utpl-cierre-vapi` (llamado por Vapi al finalizar llamada)

#### Config (CONFIG INICIAL UTPL):
```javascript
cfg = {
  db: { schema: 'public', table: 'utpl_registros', pk: 'id_negocio' },
  states: { pending: 'PENDIENTE', inProgress: 'EN_PROCESO', retry: 'REINTENTAR', done: 'FINALIZADO' },
  retryNomenclaturas: ['NC', 'VLL'],
  policy: { TZ: 'America/Guayaquil' },
  phoneFields: ['telefono1', 'telefono2', 'telefono3', 'telefono4', 'telefono5', 'telefono6'],
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
}
```

#### Nodos (32 nodos):
1. **Webhook Cierre VAPI UTPL** - Recibe `end-of-call-report` de Vapi
2. **CONFIG INICIAL UTPL** - Config con retryNomenclaturas, crmUtpl, altiva
3. **NORMALIZA EVENTO CIERRE UTPL** - Extrae campos del payload Vapi
4. **ES EVENTO CIERRE VALIDO** - Filtra eventos tipo `end-of-call-report`
5. **EXTRAE STRUCTURED OUTPUTS** - Busca 7 outputs por nombre
6. **CLASIFICA ESTADO CIERRE** - NC/VLL → REINTENTAR, resto → FINALIZADO
7. **MAPEA CAMPOS CIERRE UTPL** - Mapea 20+ campos para DB
8. **GENERAR QUERY ACTUALIZA** - SQL para UPDATE utpl_registros
9. **ACTUALIZA REGISTRO UTPL** - Ejecuta UPDATE
10. **INSERTA EN LLAMADAS UTPL** - Upsert en utpl_llamadas
11. **FALLBACK RESTORE CIERRE** - Rollback si falla
12. **IGNORAR EVENTO** - Terminal node (no-op)
13-18. **[CRM branch]** CONDICION ENVIO CRM → MAPEA MOTIVO → PREPARA SOAP → ENVIA CRM → PROCESA RESPUESTA → INSERTA EN CRM
19-28. **[Altiva branch]** CONDICION ENVIO ALTIVA → LEE TOKEN → DECIDE FLUJO → NECESITA REFRESH → SOLICITA TOKEN → GUARDA TOKEN → JOIN → PREPARA CARGA → ACTUALIZA NODO → PROCESA RESPUESTA
29-32. **[Audio branch]** CONDICION AUDIO → DESCARGAR AUDIO → PROCESAR AUDIO → SUBIR AUDIO SFTP

La rama CRM (nodos 8-13) corre en paralelo con la actualizacion DB (nodos 14-16). Si falla el CRM, no interrumpe el flujo principal.

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

### 3.4 Flujo: UTPL SIMULADOR (pruebas)

**Archivo:** `UTPL_SIMULADOR.json`
**Trigger:** Webhook `POST /utpl-simulador`

Flujo auxiliar para probar el sistema sin realizar llamadas reales. Cuando `testMode: true` en Llamadas, las peticiones a Vapi se redirigen aqui.

#### Estructura:
```
Webhook Simulador
  └─ SIMULADOR - Genera Cierre (Code node)
       │  Hash de id_negocio → asigna nomenclatura deterministica
       │  NIN (25%): genera resumen con keywords para probar matching
       │  ACE/IND/NUE/VLL/NC (75%): nomenclaturas variadas sin CRM
       └─ ENVIAR CIERRE SIMULADO (HTTP POST → /utpl-cierre-vapi)
```

#### Distribucion de nomenclaturas (por hash % 100):
| Nomenclatura | % | Accion |
|-------------|---|--------|
| ACE | 15% | FINALIZADO sin CRM |
| IND | 10% | FINALIZADO sin CRM |
| NUE | 10% | FINALIZADO sin CRM |
| VLL | 20% | REINTENTAR |
| NC | 20% | REINTENTAR |
| NIN | 25% | FINALIZADO + CRM (22 sub-motivos) |

---

## 4. CRM UTPL - Notificacion de Resultado

### 4.1 Web Service SOAP

| Parametro | Valor |
|-----------|-------|
| **Endpoint** | `http://192.168.10.112/WSUtpl/ServiceUtpl.asmx` |
| **Metodo** | POST |
| **Protocolo** | SOAP 1.1 |
| **Accion** | `RegistrarLLamada` |
| **SOAPAction** | `http://tempuri.org/RegistrarLLamada` |
| **Timeout** | 30s |
| **Agent** | `ARIA UTPL` |

### 4.2 Payload SOAP (campos enviados)

| Campo SOAP | Origen | Obligatorio |
|------------|--------|-------------|
| `codigo_negocio` | `id_negocio` | Si |
| `dealstage` | `1020923926` (NIN) o `1008735099` (NC) | Si |
| `hs_call_disposition` | UUID del sub-motivo | Si |
| `hs_call_body` | `resumen_llamada` (truncado 500 chars) | Opcional |
| `agent_name` | `ARIA UTPL` (fijo) | Si |
| `hs_call_duration` | `duracion_llamada` (segundos) | Si |
| `sales_stage_detail` | Nombre del subestado (ej: "NIN - Equivocado") | Si |
| `commitment_date` | `fecha_reagenda` | Opcional |
| `dealid` | `id_interno_negocio` | Si |
| `hs_timestamp` | `fecha_gestion HH:mm:ss` | Si |
| `scheduling_date` | - | Opcional |

### 4.3 Disparadores de notificacion

| Escenario | Flujo | Motivo asignado |
|-----------|-------|-----------------|
| Vapi retorna NIN | CierreLlamadas | Keyword matching sobre resumen_llamada → sub-motivo NIN |
| Max intentos agotados (16) | Llamadas | `NIN - No Localizable` (fa9b4696-...) |

### 4.4 Manejo de Respuesta

- **Exito:** `<httpCode>201</httpCode>` + `<idreturn>`
- **Error:** `<httpCode> != 201` + `<messagews1>`, `<messagews2>`, `<messagews3>`
- Los errores se loguean pero NO interrumpen el flujo principal

### 4.5 Respuesta SOAP (exitosa)

```xml
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope ...>
  <soap:Body>
    <RegistrarLLamadaResponse xmlns="http://tempuri.org/">
      <RegistrarLLamadaResult>
        <httpCode>201</httpCode>
        <idreturn>uuid-or-id</idreturn>
      </RegistrarLLamadaResult>
    </RegistrarLLamadaResponse>
  </soap:Body>
</soap:Envelope>
```

---

## 5. Nomenclaturas y Motivos

### 5.1 Catalogo Completo

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

### 5.2 Reglas de Reintento por Nomenclatura
- **VLL** (VOLVER A LLAMAR) → `estado_flujo = REINTENTAR`
- **NC** (NO CONTACTO) → `estado_flujo = REINTENTAR`
- **Resto** → `estado_flujo = FINALIZADO`

### 5.3 Catalogo CRM Sub-motivos (keyword matching)

Archivo: `Docs/Motivos_CRM_UTPL.csv` (27 registros: 22 NIN + 1 NC + headers)

| Sub-motivo | Keywords | hs_call_disposition UUID |
|-----------|----------|------------------------|
| NIN - Equivocado | equivocado, wrong, error numero | ec04d345-b217-43b8-886c-483caaef1207 |
| NIN - IVR De Empresa | fax, empresa, oficina, centralita | ff2dbd7a-febb-418e-b5f7-a79b21630d4a |
| NIN - Continuara por si solo | cuenta propia, por su cuenta, centro universitario | 6ec7dafd-36c9-4ac7-8fa4-aaf1d5e655ff |
| NIN - Titular Esta Fuera Del Pais | fuera del pais, extranjero, viaje | 9bb49857-d693-455f-a719-7da52a3c267f |
| NIN - Tercero o Familiar Pide No Llamar | no llame, no moleste, tercero, familiar pide | eb503640-7ac4-4296-be4d-19925e5b5c8f |
| NIN - Neg-Costos-No Tiene Dinero | dinero, costo, caro, pagar, economico | db9d6ca8-d46a-429b-a54c-ea911f60dc1d |
| NIN - Neg-Pers-Problemas De Salud | salud, enfermo, medico, hospital | b4bac679-2b71-4b0e-bdc3-5ffaac245d4a |
| NIN - Informacion Para Un Familiar | para un familiar, para mi hijo | 7157a907-42d1-4ba1-a302-bc8c6fe7757d |
| NIN - Neg-Pers-Aun No Es Bachiller | bachiller, colegio, terminando | 946823bc-a033-47ab-9461-56bbe36ba649 |
| NIN - Negativa-Pers-Titular Fallecido | fallecio, fallecido, murio | fca8fec9-9636-46e8-b08c-51f95a1861f9 |
| NIN - Estudiante Utpl 2Do. En Adelante | estudiante continuo, ya estudio | 7b45b4fe-69f6-4b74-b14a-39b16f7df70f |
| NIN - Negativa-Pers-Trabaja En La Utpl | trabaja en utpl, empleado utpl | ed5610f2-00e8-4284-b62e-0becd4b25e9a |
| NIN - Interesado En Maestria | maestria, posgrado, postgrado | 2efa7cc1-9785-401b-b13e-b133c42ae62e |
| NIN - No Ha Solicitado Informacion | no solicite, no pedi informacion | 491f0fd2-b01e-43fa-b0e7-8e4a59e1abb9 |
| NIN - Mala Experiencia Con Utpl | mala experiencia, mal servicio, queja | 2ba903ac-d1f4-43f3-89c9-1adc67b373c0 |
| NIN - No Tiene Tiempo Para Estudiar | no tengo tiempo, ocupado, falta de tiempo | 5fadfbe1-909d-44e1-84d7-63a8a184cc7f |
| NIN - No Esta Interesado En Modalidad En Linea | presencial, no en linea | 6ab24c69-4728-48d2-8950-36d6fd47627d |
| NIN - Estudia Ahora En Otra Univ | otra universidad, ya estudio en | 7b7283a7-dd21-4601-962d-7f867f0dcb3a |
| NIN - Carreras Ofertadas No Desea | no ofertan, no tiene la carrera | f6828cdb-b9c4-4e4b-a3f0-cc8e372c232f |
| NIN - Interesado Cursos Form. Perm | cursos, taller, formacion permanente | ee5da155-3a0f-41fd-82e5-72a99d3f19d9 |
| NIN - Interesado Proximo periodo | proximo periodo, siguiente ciclo | c941a32d-0909-46f4-a72b-ca94adbde489 |
| NIN - No Localizable | no localizable, no contesta | fa9b4696-95d1-4b4a-906f-4b0b7b7f155b |
| NC - No Contacto | (buzon de voz) | 569d4307-4da7-45e0-9c5a-7530a99aca5d |

**Default (sin match):** `NIN - No Desea Continuar Con Proceso Matricula` (f6cf9978-e0e0-4cd9-9605-3e4baca78289)

---

## 5. Altiva - Actualizacion de Nodo

### 5.1 API Endpoints

| Parametro | Valor |
|-----------|-------|
| **Auth URL** | `http://192.168.10.238:91/api/auth/token` |
| **Actualizar Nodo** | `http://192.168.10.238:91/api/v1/altiva/nodo/actualizar` |
| **Auth method** | JWT Bearer (24h expiry) |
| **client_id** | `7` |
| **client_secret** | `ug7wMESTpOPPmdDC3KoEyYpVXskcOqRWnfHFZm8X` |

### 5.2 Token Storage
Cacheado en `utpl_config` table (key: `altiva_token`). Se renueva automáticamente cuando expira.

### 5.3 Payload (Actualizar Nodo)

| Campo | Origen | Descripcion |
|-------|--------|-------------|
| `nuic` | `cedula` del lead | Cédula del usuario |
| `nombre_corto_campania` | `nombre_corto_campania` del registro (fallback: cfg.altiva.nombreCampania) | Nombre corto de campaña |
| `nodo` | Según nomenclatura | `1` = no interesado/agotado, `2` = interesado |

### 5.4 Disparadores

| Escenario | Flujo | nodo |
|-----------|-------|------|
| Vapi retorna NIN | CierreLlamadas | `1` |
| Vapi retorna ACE, IND, NUE | CierreLlamadas | `2` |
| Max intentos agotados | Llamadas | `1` |

---

## 6. SFTP Audio Download

### 6.1 Flujo
```
INSERTA EN CRM UTPL
  └── CONDICION AUDIO (IF: link_audio_vapi not empty)
        └── DESCARGAR AUDIO (HTTP GET, binary, timeout 300s)
              └── PROCESAR AUDIO (Code: detect ext from URL)
                    └── SUBIR AUDIO SFTP (FTP upload, protocol sftp)
```

### 6.2 Path SFTP
```
/UTPL/llamadas/YYYYMMDD/{id_llamada}.{ext}
```
Ejemplo: `/UTPL/llamadas/20260529/sim-abc123.mp3`

### 6.3 Credencial
`SFTP account` (ID: `vEofEOfYOxdhgSvj`), misma que usa el proyecto Solidario.

### 6.4 Manejo de Errores
- Sin audio: salta la rama
- Error de descarga o SFTP: log, no interrumpe flujo

---

## 7. Configuracion Vapi

### 5.1 Endpoints
- **Base URL:** `https://api.vapi.ai`
- **Call endpoint:** `POST /call`
- **API Key:** `484afd71-2703-4852-8580-9629620dde82`

### 5.2 Asistentes
| ID | Nombre | Modalidad |
|----|--------|-----------|
| `cc4bbac0-0736-48f6-8175-0bfe4c4e8a76` | utpl mel | MODALIDAD EN LINEA |
| `d61d17dc-6e48-4ce7-bfdb-3dc40dcd329e` | utpl posgrado | POSGRADO |
| `638fb59f-0522-4d76-9ca4-a47609f64961` | utpl tecnologico | TECNOLÓGICO |

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

### 6.4 scripts/cargar_datos_prueba.js
- **Proposito:** Generar SQL con 100 leads sinteticos para pruebas
- **Ejecucion:** `node scripts/cargar_datos_prueba.js`
- **Salida:** `pruebas/leads_prueba.sql` (ejecutar en Supabase SQL Editor)
- **Escenarios cubiertos:** Fresh, mid-cycle, window limit, near max, agotados, sin telefonos, sin id_interno

### 6.5 scripts/validar_sql.js
- **Proposito:** Validar constraints del SQL generado (telefono_index, win_tries, intentos)
- **Ejecucion:** `node scripts/validar_sql.js`

### 6.6 flujo_n8n/UTPL_SIMULADOR.json
- **Proposito:** Prueba end-to-end sin llamadas reales
- **Activacion:** Importar en n8n, activar, y poner `testMode: true` en Llamadas
- **Funcionamiento:** Recibe payload de llamada, genera cierre sintetico variado, reenvia a CierreLlamadas

---

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
| `modalidad` | VARCHAR(50) | MODALIDAD EN LINEA, POSGRADO, TECNOLÓGICO, general |
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
