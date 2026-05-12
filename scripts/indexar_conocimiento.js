/* ============================================================
   UTPL - Indexador de Base de Conocimiento
   Procesa .docx → chunks → embeddings → Supabase
   ============================================================

   Uso:
   1. npm install mammoth openai @supabase/supabase-js dotenv
   2. Crear .env con OPENAI_API_KEY=sk-...
   3. node scripts/indexar_conocimiento.js
   ============================================================ */

require('dotenv').config({ path: __dirname + '/../.env' });
const fs = require('fs');
const path = require('path');
const mammoth = require('mammoth');
const OpenAI = require('openai');
const { createClient } = require('@supabase/supabase-js');

// === CONFIGURACION ===
const BASE_DIR = path.join(__dirname, '..', 'BaseConocimiento');
const SUPABASE_URL = 'https://suokpkpzpfvadwemxzfa.supabase.co';
const SUPABASE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InN1b2twa3B6cGZ2YWR3ZW14emZhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkyNjM0ODgsImV4cCI6MjA3NDgzOTQ4OH0.bSMXRoVj_5vjIftDV1VcjauQQhYhK5AL7fz3VFln72A';
const TABLE = 'utpl_conocimiento';
const CHUNK_SIZE = 1800;  // caracteres por chunk (~450 tokens)
const CHUNK_OVERLAP = 200; // solapamiento entre chunks
const BATCH_SIZE = 10;     // cuantos embeddings generar por lote
const DELAY_MS = 200;      // delay entre lotes (rate limiting)

// Mapeo carpeta → modalidad
const MODALIDAD_MAP = {
  'Mel': 'MODALIDAD EN LINEA',
  'Posgrado': 'POSGRADO',
  'Tecnologico': 'TECNOLOGICO',
};

// === INICIALIZACION ===
const openaiKey = process.env.OPENAI_API_KEY;
if (!openaiKey) {
  console.error('ERROR: Define OPENAI_API_KEY en .env o variable de entorno');
  process.exit(1);
}

const openai = new OpenAI({ apiKey: openaiKey });
const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);

// === UTILIDADES ===
function chunkText(text, size, overlap) {
  const chunks = [];
  let start = 0;
  while (start < text.length) {
    let end = start + size;
    if (end < text.length) {
      // Buscar corte natural (punto, salto de linea) cerca del limite
      const searchEnd = Math.min(end + 200, text.length);
      const cutPoints = ['\n\n', '\n', '. ', '? ', '! ', '; '];
      let bestCut = end;
      for (const cp of cutPoints) {
        const idx = text.lastIndexOf(cp, searchEnd);
        if (idx > start + 100) { bestCut = idx + cp.length; break; }
      }
      end = bestCut;
    }
    chunks.push(text.slice(start, end).trim());
    start = end - overlap;
    if (start < 0) start = 0;
    if (start >= text.length) break;
  }
  return chunks.filter(c => c.length > 50);
}

async function extractText(filePath) {
  const buffer = fs.readFileSync(filePath);
  const result = await mammoth.extractRawText({ buffer });
  return result.value.trim();
}

async function generateEmbeddings(texts) {
  const response = await openai.embeddings.create({
    model: 'text-embedding-3-small',
    input: texts,
  });
  return response.data.map(d => d.embedding);
}

async function sleep(ms) { return new Promise(r => setTimeout(r, ms)); }

// === MAIN ===
async function main() {
  console.log('UTPL - Indexador de Base de Conocimiento\n');

  // Verificar conexion Supabase
  const { error: connErr } = await supabase.from(TABLE).select('id').limit(1);
  if (connErr) {
    console.error('Error conectando a Supabase:', connErr.message);
    process.exit(1);
  }
  console.log('Supabase conectado OK\n');

  // Recolectar archivos
  const files = [];
  for (const [dirName, modalidad] of Object.entries(MODALIDAD_MAP)) {
    const dirPath = path.join(BASE_DIR, dirName);
    if (!fs.existsSync(dirPath)) {
      console.log(`  [!] Carpeta no encontrada: ${dirPath}`);
      continue;
    }
    const docxFiles = fs.readdirSync(dirPath).filter(f => f.endsWith('.docx'));
    for (const f of docxFiles) {
      files.push({ path: path.join(dirPath, f), modalidad, fuente: f });
    }
    console.log(`  ${dirName}: ${docxFiles.length} archivos`);
  }

  // Archivo general (FAQ)
  const generalFile = path.join(BASE_DIR, 'BANCO DE PREGUNTAS Y RESPUESTAS.docx');
  if (fs.existsSync(generalFile)) {
    files.push({ path: generalFile, modalidad: 'general', fuente: 'BANCO DE PREGUNTAS Y RESPUESTAS.docx' });
    console.log(`  general: 1 archivo (FAQ)`);
  }

  console.log(`\nTotal: ${files.length} archivos a procesar\n`);
  console.log('Iniciando indexacion...\n');

  let totalChunks = 0;
  let totalEmbeddings = 0;
  let errors = 0;

  for (let fi = 0; fi < files.length; fi++) {
    const file = files[fi];
    const name = path.basename(file.fuente, '.docx');
    process.stdout.write(`[${fi + 1}/${files.length}] ${file.modalidad} - ${name} ... `);

    try {
      // Extraer texto
      const text = await extractText(file.path);
      if (!text || text.length < 50) {
        console.log('vacio, saltando');
        continue;
      }

      // Chunking
      const chunks = chunkText(text, CHUNK_SIZE, CHUNK_OVERLAP);
      if (chunks.length === 0) {
        console.log('sin chunks, saltando');
        continue;
      }

      // Generar embeddings por lotes
      const rows = [];
      for (let i = 0; i < chunks.length; i += BATCH_SIZE) {
        const batch = chunks.slice(i, i + BATCH_SIZE);
        const embeddings = await generateEmbeddings(batch);

        for (let j = 0; j < batch.length; j++) {
          rows.push({
            modalidad: file.modalidad,
            fuente: file.fuente,
            titulo: `${name} (parte ${i + j + 1})`,
            contenido: batch[j],
            embedding: embeddings[j],
            metadata: { archivo: file.fuente, chunk_index: i + j, total_chunks: chunks.length }
          });
        }

        totalEmbeddings += batch.length;
        if (i + BATCH_SIZE < chunks.length) await sleep(DELAY_MS);
      }

      // Insertar en Supabase
      const { error: insErr } = await supabase.from(TABLE).insert(rows);
      if (insErr) {
        console.log(`ERROR DB: ${insErr.message}`);
        errors++;
      } else {
        totalChunks += rows.length;
        console.log(`${rows.length} chunks OK`);
      }
    } catch (err) {
      console.log(`ERROR: ${err.message}`);
      errors++;
    }
  }

  console.log('\n=== RESUMEN ===');
  console.log(`Archivos procesados: ${files.length}`);
  console.log(`Chunks indexados:    ${totalChunks}`);
  console.log(`Embeddings generados:${totalEmbeddings}`);
  console.log(`Errores:             ${errors}`);
  console.log('\nIndexacion completada.');
}

main().catch(err => {
  console.error('Error fatal:', err);
  process.exit(1);
});
