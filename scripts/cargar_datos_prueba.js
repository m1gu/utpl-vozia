// Carga 100 leads sinteticos a Supabase (utpl_registros)
// Genera SQL INSERT statements en pruebas/leads_prueba.sql
// Uso: node scripts/cargar_datos_prueba.js
// Luego ejecutar el SQL en Supabase SQL Editor

const fs = require('fs');
const path = require('path');

// ---- Data pools ----
const modalidades = ['MODALIDAD EN LINEA', 'POSGRADO', 'TECNOLÓGICO'];
const carreras = {
  'MODALIDAD EN LINEA': ['ADMINISTRACION DE EMPRESAS','DERECHO','PSICOLOGIA','CONTABILIDAD Y AUDITORIA','TURISMO','ECONOMIA','FINANZAS','COMUNICACION','EDUCACION BASICA','TECNOLOGIAS DE LA INFORMACION'],
  'POSGRADO': ['DERECHO CONSTITUCIONAL','DERECHO PENAL','DERECHO TRIBUTARIO','GERENCIA DE INSTITUCIONES DE SALUD','GESTION FINANCIERA','BIOECONOMIA','GESTION DE LA CALIDAD','SEGURIDAD INDUSTRIAL'],
  'TECNOLÓGICO': ['CONTABILIDAD Y ASESORIA TRIBUTARIA','MARKETING TURISTICO DIGITAL','NEGOCIACION Y VENTAS','MODELADO BIM','CREACION AUDIOVISUAL DIGITAL']
};
const nombres = ['Juan','Maria','Carlos','Ana','Pedro','Laura','Luis','Sofia','Diego','Elena','Andres','Valentina','Jose','Camila','Miguel','Daniela','Fernando','Gabriela','Javier','Paola','Victor','Rosa','Oscar','Natalia','Roberto','Adriana','Gustavo','Monica','Ricardo','Tatiana'];
const apellidos = ['Perez','Gomez','Lopez','Rodriguez','Martinez','Sanchez','Torres','Ramirez','Flores','Vargas','Morales','Ruiz','Ortiz','Castro','Herrera','Medina','Reyes','Mendoza','Silva','Paredes'];
const phonesEcuador = [
  ['0999999001','0999999002'],['0999999003',''],['0999999004','0999999005'],
  ['0999999006','0999999007'],['0999999008',''],['0999999009','0999999010'],
  ['0999999011',''],['0999999012','0999999013'],['0999999014','0999999015'],
  ['0999999016',''],['0999999017','0999999018'],['0999999019',''],
  ['0999999020','0999999021'],['0999999022','0999999023'],['0999999024',''],
  ['0999999025',''],['0999999026','0999999027'],['0999999028',''],
  ['0999999029','0999999030']
];

function pick(arr) { return arr[Math.floor(Math.random() * arr.length)]; }
function fechaISO(diasOffset, horas, minutos) {
  const d = new Date();
  d.setDate(d.getDate() + diasOffset);
  d.setHours(horas, minutos, 0, 0);
  return d.toISOString();
}

const esc = (s) => {
  if (s === null || s === undefined) return 'NULL';
  const str = String(s).replace(/'/g, "''");
  return `'${str}'`;
};

const records = [];
let idx = 0;

// Build record helper
function add(n, estado, intentosFn, winTriesFn, winStampFn, fechaReagFn, telIndexFn) {
  for (let i = 0; i < n; i++, idx++) {
    const mod = modalidades[idx % 3];
    const ph = phonesEcuador[(idx + i) % phonesEcuador.length];
    const intentosVal = typeof intentosFn === 'function' ? intentosFn(i) : intentosFn;
    const winTriesVal = typeof winTriesFn === 'function' ? winTriesFn(i) : winTriesFn;
    const winStampVal = typeof winStampFn === 'function' ? winStampFn(i) : winStampFn;
    const fechaReagVal = typeof fechaReagFn === 'function' ? fechaReagFn(i) : fechaReagFn;
    const telIndexVal = typeof telIndexFn === 'function' ? telIndexFn(i, intentosVal) : (telIndexFn ?? intentosVal % 2);

    records.push({
      id_negocio: `SIM-${String(idx+1).padStart(4,'0')}`,
      id_interno_negocio: `INT-${String(idx+1).padStart(4,'0')}`,
      cedula: String(1700000001 + idx).padStart(10,'0'),
      nombre: nombres[idx % nombres.length],
      apellido: apellidos[idx % apellidos.length],
      modalidad: mod,
      producto: pick(carreras[mod]),
      telefono1: ph[0],
      telefono2: ph[1] || '',
      telefono3: '', telefono4: '', telefono5: '', telefono6: '',
      intentos_llamada: intentosVal,
      win_tries: winTriesVal,
      win_stamp: winStampVal || '',
      estado_flujo: estado,
      fecha_reagenda: fechaReagVal || null,
      telefono_index: telIndexVal,
      fecha_ultima_llamada: intentosVal > 0 ? fechaISO(-1, 10, 0) : null,
      updated_at: new Date().toISOString()
    });
  }
}

// Gruppe 1: Fresh leads (20) - PENDIENTE, intentos=0
add(20, 'PENDIENTE', 0, 0, '', null, 0);

// Grupo 2: Mid-cycle retries (15) - REINTENTAR, intentos 3-8
add(15, 'REINTENTAR', i => 3 + (i % 6), i => (3 + (i % 6)) % 3, i => i % 2 === 0 ? '' : `MANANA_2026-05-${String(20+i).padStart(2,'0')}`, fechaISO(-1, 10, 0), (i, intentos) => intentos % 6);

// Grupo 3: Window limit (10) - win_tries=3
add(10, 'REINTENTAR', i => 6 + (i % 5), 3, i => `MANANA_2026-05-${String(20+i).padStart(2,'0')}`, i => i < 5 ? fechaISO(-1, 9, 30) : fechaISO(0, 9, 30), (i, intentos) => intentos % 2);

// Grupo 4: Near max (15) - intentos 14-15
add(15, 'REINTENTAR', i => 14 + (i % 2), i => i % 3, i => `TARDE_2026-05-${String(22+(i%10)).padStart(2,'0')}`, fechaISO(-1, 14, 0), (i, intentos) => (intentos + i) % 3);

// Grupo 5: Max attempts AGOTADO (5) - intentos=16
add(5, 'REINTENTAR', 16, 3, 'NOCHE_2026-05-27', fechaISO(-1, 19, 0), 0);

// Grupo 6: No phones (5)
for (let i = 0; i < 5; i++, idx++) addPhoneless();

function addPhoneless() {
  const mod = modalidades[idx % 3];
  records.push({
    id_negocio: `SIM-${String(idx+1).padStart(4,'0')}`,
    id_interno_negocio: '',
    cedula: String(1700000001 + idx).padStart(10,'0'),
    nombre: nombres[idx % nombres.length],
    apellido: apellidos[idx % apellidos.length],
    modalidad: mod,
    producto: pick(carreras[mod]),
    telefono1: '', telefono2: '', telefono3: '',
    telefono4: '', telefono5: '', telefono6: '',
    intentos_llamada: 0, win_tries: 0, win_stamp: '',
    estado_flujo: 'PENDIENTE', fecha_reagenda: null,
    telefono_index: 0, fecha_ultima_llamada: null,
    updated_at: new Date().toISOString()
  });
}

// Grupo 7: fecha_reagenda futura (10)
add(10, 'REINTENTAR', i => 2 + (i % 3), i => i % 2, '', fechaISO(1, 9, 0), i => i % 2);

// Grupo 8: Mixed variedad (15) - intentos diversos, algunos sin id_interno
for (let i = 0; i < 15; i++, idx++) {
  const mod = modalidades[idx % 3];
  const ph = phonesEcuador[(idx + i) % phonesEcuador.length];
  const intentos = (i * 2) % 12 + (i % 3);
  const sinIdInterno = i >= 8;
  records.push({
    id_negocio: `SIM-${String(idx+1).padStart(4,'0')}`,
    id_interno_negocio: sinIdInterno ? '' : `INT-${String(idx+1).padStart(4,'0')}`,
    cedula: String(1700000001 + idx).padStart(10,'0'),
    nombre: nombres[idx % nombres.length],
    apellido: apellidos[idx % apellidos.length],
    modalidad: mod,
    producto: pick(carreras[mod]),
    telefono1: ph[0], telefono2: ph[1] || '',
    telefono3: '', telefono4: '', telefono5: '', telefono6: '',
    intentos_llamada: intentos,
    win_tries: intentos % 3,
    win_stamp: intentos > 0 ? `MANANA_2026-05-${String(20+(i%10)).padStart(2,'0')}` : '',
    estado_flujo: intentos === 0 ? 'PENDIENTE' : 'REINTENTAR',
    fecha_reagenda: intentos > 0 ? fechaISO(-1, 10 + (i % 7), 0) : null,
    telefono_index: intentos > 0 ? intentos % 2 : 0,
    fecha_ultima_llamada: intentos > 0 ? fechaISO(-1, 10 + (i % 7), 0) : null,
    updated_at: new Date().toISOString()
  });
}

// Grupo 9: Adicional para completar 100 (5) - sin id_interno
for (let i = 0; i < 5; i++, idx++) {
  const mod = modalidades[idx % 3];
  const ph = phonesEcuador[(idx + i) % phonesEcuador.length];
  records.push({
    id_negocio: `SIM-${String(idx+1).padStart(4,'0')}`,
    id_interno_negocio: '',
    cedula: String(1700000001 + idx).padStart(10,'0'),
    nombre: nombres[idx % nombres.length],
    apellido: apellidos[idx % apellidos.length],
    modalidad: mod,
    producto: pick(carreras[mod]),
    telefono1: ph[0], telefono2: '',
    telefono3: '', telefono4: '', telefono5: '', telefono6: '',
    intentos_llamada: 0, win_tries: 0, win_stamp: '',
    estado_flujo: 'PENDIENTE', fecha_reagenda: null,
    telefono_index: 0, fecha_ultima_llamada: null,
    updated_at: new Date().toISOString()
  });
}

console.log(`Total records generados: ${records.length}`);

// Build SQL
const cols = [
  'id_negocio','id_interno_negocio','cedula','nombre','apellido',
  'modalidad','producto','telefono1','telefono2','telefono3',
  'telefono4','telefono5','telefono6','intentos_llamada','win_tries',
  'win_stamp','estado_flujo','fecha_reagenda','telefono_index',
  'fecha_ultima_llamada','updated_at'
];

let sql = '';
sql += '-- Limpiar datos de prueba anteriores\n';
sql += "DELETE FROM public.utpl_llamadas WHERE id_llamada LIKE 'sim-%';\n";
sql += "DELETE FROM public.utpl_crm WHERE id_negocio LIKE 'SIM-%';\n";
sql += "DELETE FROM public.utpl_registros WHERE id_negocio LIKE 'SIM-%';\n\n";

// Upsert records
const batchSize = 10;
for (let b = 0; b < records.length; b += batchSize) {
  const batch = records.slice(b, b + batchSize);
  sql += 'INSERT INTO public.utpl_registros (' + cols.join(', ') + ') VALUES\n';
  sql += batch.map(r => {
    return '  (' + cols.map(c => esc(r[c])).join(', ') + ')';
  }).join(',\n');
  sql += '\nON CONFLICT (id_negocio) DO UPDATE SET\n';
  sql += '  id_interno_negocio = EXCLUDED.id_interno_negocio,\n';
  sql += '  intentos_llamada = EXCLUDED.intentos_llamada,\n';
  sql += '  win_tries = EXCLUDED.win_tries,\n';
  sql += '  win_stamp = EXCLUDED.win_stamp,\n';
  sql += '  estado_flujo = EXCLUDED.estado_flujo,\n';
  sql += '  fecha_reagenda = EXCLUDED.fecha_reagenda,\n';
  sql += '  telefono_index = EXCLUDED.telefono_index,\n';
  sql += '  fecha_ultima_llamada = EXCLUDED.fecha_ultima_llamada,\n';
  sql += '  updated_at = EXCLUDED.updated_at;\n\n';
}

const outDir = path.join(__dirname, '..', 'pruebas');
if (!fs.existsSync(outDir)) fs.mkdirSync(outDir, { recursive: true });
const outFile = path.join(outDir, 'leads_prueba.sql');
fs.writeFileSync(outFile, sql, 'utf8');

// Stats
const fresh = records.filter(r => r.estado_flujo === 'PENDIENTE').length;
const retry = records.filter(r => r.estado_flujo === 'REINTENTAR').length;
const agotados = records.filter(r => r.intentos_llamada >= 16).length;
const sinPh = records.filter(r => !r.telefono1 && !r.telefono2).length;
const sinId = records.filter(r => !r.id_interno_negocio).length;

console.log(`SQL generado: ${outFile}`);
console.log(`PENDIENTE: ${fresh} | REINTENTAR: ${retry}`);
console.log(`AGOTADOS (16): ${agotados} | Sin tel: ${sinPh} | Sin id_interno: ${sinId}`);
console.log('Ejecuta este SQL en Supabase SQL Editor');
