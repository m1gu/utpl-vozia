// Generador de 100 leads sinteticos para prueba de flujos UTPL
// Uso: node scripts/generar_csv_prueba.js

const fs = require('fs');
const path = require('path');

const outputDir = path.join(__dirname, '..', 'pruebas');
if (!fs.existsSync(outputDir)) fs.mkdirSync(outputDir, { recursive: true });
const outputFile = path.join(outputDir, 'leads_prueba_100.csv');

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

// Build records
const records = [];
let idx = 0;

// ---- GRUPO 1: Fresh leads (20) - PENDIENTE, intentos=0 ----
for (let i = 0; i < 20; i++, idx++) {
  const mod = modalidades[i % 3];
  const ph = phonesEcuador[i % phonesEcuador.length];
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
    intentos_llamada: 0,
    win_tries: 0,
    win_stamp: '',
    estado_flujo: 'PENDIENTE',
    fecha_reagenda: '',
    telefono_index: 0
  });
}

// ---- GRUPO 2: Mid-cycle retries (15) - REINTENTAR, intentos 3-8 ----
for (let i = 0; i < 15; i++, idx++) {
  const mod = modalidades[i % 3];
  const ph = phonesEcuador[(i+5) % phonesEcuador.length];
  const intentos = 3 + (i % 6);
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
    intentos_llamada: intentos,
    win_tries: intentos % 3,
    win_stamp: (i % 2 === 0) ? '' : `MANANA_2026-05-${String(20+i).padStart(2,'0')}`,
    estado_flujo: 'REINTENTAR',
    fecha_reagenda: fechaISO(-1, 10, 0),
    telefono_index: intentos % phonesEcuador.length
  });
}

// ---- GRUPO 3: Window limit (10) - win_tries=3, variando intentos ----
for (let i = 0; i < 10; i++, idx++) {
  const mod = modalidades[i % 3];
  const ph = phonesEcuador[(i+10) % phonesEcuador.length];
  const intentos = 6 + (i % 5);
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
    intentos_llamada: intentos,
    win_tries: 3,
    win_stamp: `MANANA_2026-05-${String(20+i).padStart(2,'0')}`,
    estado_flujo: 'REINTENTAR',
    fecha_reagenda: fechaISO(i < 5 ? -1 : 0, 9, 30),
    telefono_index: intentos % 2
  });
}

// ---- GRUPO 4: Near max attempts (15) - intentos 14-15 ----
for (let i = 0; i < 15; i++, idx++) {
  const mod = modalidades[i % 3];
  const ph = phonesEcuador[(i+3) % phonesEcuador.length];
  const intentos = 14 + (i % 2);
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
    intentos_llamada: intentos,
    win_tries: i % 3,
    win_stamp: `TARDE_2026-05-${String(22+(i%10)).padStart(2,'0')}`,
    estado_flujo: 'REINTENTAR',
    fecha_reagenda: fechaISO(-1, 14, 0),
    telefono_index: (intentos + i) % 3
  });
}

// ---- GRUPO 5: At max attempts AGOTADO (5) - intentos=16 ----
for (let i = 0; i < 5; i++, idx++) {
  const mod = modalidades[i % 3];
  const ph = phonesEcuador[i % phonesEcuador.length];
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
    intentos_llamada: 16,
    win_tries: 3,
    win_stamp: `NOCHE_2026-05-27`,
    estado_flujo: 'REINTENTAR',
    fecha_reagenda: fechaISO(-1, 19, 0),
    telefono_index: 0
  });
}

// ---- GRUPO 6: No phones (5) ----
for (let i = 0; i < 5; i++, idx++) {
  const mod = modalidades[i % 3];
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
    intentos_llamada: 0,
    win_tries: 0,
    win_stamp: '',
    estado_flujo: 'PENDIENTE',
    fecha_reagenda: '',
    telefono_index: 0
  });
}

// ---- GRUPO 7: fecha_reagenda en futuro (10) - no listos para llamar ----
for (let i = 0; i < 10; i++, idx++) {
  const mod = modalidades[i % 3];
  const ph = phonesEcuador[(i+7) % phonesEcuador.length];
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
    intentos_llamada: 2 + (i % 3),
    win_tries: i % 2,
    win_stamp: '',
    estado_flujo: 'REINTENTAR',
    fecha_reagenda: fechaISO(1, 9, 0),
    telefono_index: i % 2
  });
}

// ---- GRUPO 8: Mixed - intentos variados, algunos sin id_interno ----
for (let i = 0; i < 13; i++, idx++) {
  const mod = modalidades[i % 3];
  const ph = phonesEcuador[i % phonesEcuador.length];
  const intentos = (i * 2) % 12 + (i % 3);
  records.push({
    id_negocio: `SIM-${String(idx+1).padStart(4,'0')}`,
    id_interno_negocio: i < 6 ? `INT-${String(idx+1).padStart(4,'0')}` : '',
    cedula: String(1700000001 + idx).padStart(10,'0'),
    nombre: nombres[idx % nombres.length],
    apellido: apellidos[idx % apellidos.length],
    modalidad: mod,
    producto: pick(carreras[mod]),
    telefono1: ph[0],
    telefono2: ph[1] || '',
    telefono3: '', telefono4: '', telefono5: '', telefono6: '',
    intentos_llamada: intentos,
    win_tries: intentos % 3,
    win_stamp: intentos > 0 ? `MANANA_2026-05-${String(20+i).padStart(2,'0')}` : '',
    estado_flujo: intentos === 0 ? 'PENDIENTE' : 'REINTENTAR',
    fecha_reagenda: intentos > 0 ? fechaISO(-1, 10 + (i % 7), 0) : '',
    telefono_index: intentos > 0 ? intentos % 2 : 0
  });
}

// ---- GRUPO 9: Adicional para completar 100 (7) - solo id_negocio no interno ----
for (let i = 0; i < 7; i++, idx++) {
  const mod = modalidades[i % 3];
  const ph = phonesEcuador[(i+15) % phonesEcuador.length];
  records.push({
    id_negocio: `SIM-${String(idx+1).padStart(4,'0')}`,
    id_interno_negocio: '',
    cedula: String(1700000001 + idx).padStart(10,'0'),
    nombre: nombres[idx % nombres.length],
    apellido: apellidos[idx % apellidos.length],
    modalidad: mod,
    producto: pick(carreras[mod]),
    telefono1: ph[0],
    telefono2: '',
    telefono3: '', telefono4: '', telefono5: '', telefono6: '',
    intentos_llamada: 0,
    win_tries: 0,
    win_stamp: '',
    estado_flujo: 'PENDIENTE',
    fecha_reagenda: '',
    telefono_index: 0
  });
}

// CSV header
const headers = [
  'id_negocio','id_interno_negocio','cedula','nombre','apellido',
  'modalidad','producto','telefono1','telefono2','telefono3',
  'telefono4','telefono5','telefono6','intentos_llamada','win_tries',
  'win_stamp','estado_flujo','fecha_reagenda','telefono_index'
];

// CSV output
const lines = [];
lines.push(headers.join(','));

for (const r of records) {
  const row = headers.map(h => {
    const v = r[h];
    if (v === null || v === undefined) return '';
    return String(v).includes(',') ? `"${v}"` : String(v);
  });
  lines.push(row.join(','));
}

fs.writeFileSync(outputFile, lines.join('\n') + '\n', 'utf8');

// Statistics
let fresh = records.filter(r => r.estado_flujo === 'PENDIENTE').length;
let retry = records.filter(r => r.estado_flujo === 'REINTENTAR').length;
let agotados = records.filter(r => r.intentos_llamada >= 16).length;
let nearMax = records.filter(r => r.intentos_llamada >= 14 && r.intentos_llamada <= 15).length;
let sinPhones = records.filter(r => !r.telefono1 && !r.telefono2 && !r.telefono3 && !r.telefono4 && !r.telefono5 && !r.telefono6).length;
let sinIdInterno = records.filter(r => !r.id_interno_negocio).length;
let winLimit = records.filter(r => r.win_tries >= 3).length;
let conFechaFutura = records.filter(r => r.fecha_reagenda && new Date(r.fecha_reagenda) > new Date()).length;

console.log(`CSV generado: ${outputFile}`);
console.log(`Total records: ${records.length}`);
console.log(`PENDIENTE: ${fresh} | REINTENTAR: ${retry}`);
console.log(`Sin telefonos: ${sinPhones}  | Win tries >=3: ${winLimit}`);
console.log(`Max intentos (16): ${agotados} | Cerca del max (14-15): ${nearMax}`);
console.log(`Sin id_interno_negocio: ${sinIdInterno}  | Fecha reagenda futura: ${conFechaFutura}`);
console.log(`Modalidades: MEL=${records.filter(r=>r.modalidad==='MODALIDAD EN LINEA').length}, POSG=${records.filter(r=>r.modalidad==='POSGRADO').length}, TEC=${records.filter(r=>r.modalidad==='TECNOLOGICO').length}`);
