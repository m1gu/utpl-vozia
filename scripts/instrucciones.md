# Indexar Base de Conocimiento RAG

## Requisitos

- Node.js 18+
- Dependencias instaladas:
  ```bash
  npm install mammoth openai @supabase/supabase-js dotenv
  ```
- Variable `OPENAI_API_KEY` definida en `.env` en la raiz del proyecto

## Estructura de carpetas

Colocar los archivos `.docx` en `BaseConocimiento/`. El script escanea automaticamente:

```
BaseConocimiento/
  ├── archivo_general.docx          → modalidad: 'general'
  ├── Mel/*.docx                    → modalidad: 'MODALIDAD EN LINEA'
  ├── Posgrado/*.docx               → modalidad: 'POSGRADO'
  ├── Tecnologico/*.docx            → modalidad: 'TECNOLOGICO'
  └── NuevaCarpeta/*.docx           → modalidad: 'NUEVACARPETA' (con WARN)
```

- Archivos en la raiz de `BaseConocimiento/` se asignan a modalidad `general`
- Subdirectorios: la modalidad se infiere del nombre de la carpeta
- Carpetas sin `.docx` se ignoran
- Carpetas con nombre no reconocido emiten un WARN y usan el nombre como modalidad

## Ejecutar

```bash
node scripts/indexar_conocimiento.js
```

## Que hace el script

1. Conecta a Supabase
2. Elimina todos los registros de `utpl_conocimiento` (re-indexacion completa)
3. Escanea `BaseConocimiento/` en busca de archivos `.docx`
4. Extrae texto de cada archivo (via mammoth)
5. Divide en chunks de ~1800 caracteres con solapamiento de 200
6. Genera embeddings con OpenAI `text-embedding-3-small`
7. Inserta en Supabase tabla `utpl_conocimiento`

## Salida esperada

```
UTPL - Indexador de Base de Conocimiento

Supabase conectado OK
Tabla utpl_conocimiento limpiada OK

  general (raiz): 1 archivos
  Mel/ (MODALIDAD EN LINEA): 26 archivos
  Posgrado/ (POSGRADO): 20 archivos
  Tecnologico/ (TECNOLOGICO): 5 archivos

Total: 52 archivos a procesar

Iniciando indexacion...

[1/52] MODALIDAD EN LINEA - archivo1 ... 12 chunks OK
...

=== RESUMEN ===
Archivos procesados: 52
Chunks indexados:    173
Embeddings generados: 173
Errores:             0

Indexacion completada.
```
