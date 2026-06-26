const fs = require('fs');
const path = require('path');

const FILE = path.join(__dirname, '..', 'flujo_n8n', 'Utpl_Llamadas.json');
const d = JSON.parse(fs.readFileSync(FILE, 'utf8'));

const capturaNode = d.nodes.find(x => x.name === 'CAPTURA SNAPSHOT');
const capturaX = capturaNode.position[0];
const capturaY = capturaNode.position[1];

// Remove old GENERA node if exists
d.nodes = d.nodes.filter(x => x.name !== 'GENERA SQL PRE-LLAMADA');

// Build jsCode as a JavaScript string for the JSON file
// Using double quotes for strings inside the Code so single quotes are literal
const jsCode = 
  "return items.map(item => {\n" +
  "  const esc = function(s) { return String(s || '').replace(/'/g, \"''\"); };\n" +
  "  const cfg = $items('CONFIG INICIAL UTPL', 0, 0)[0].json.cfg;\n" +
  "  item.json.query = \"UPDATE \" + cfg.db.schema + \".\" + cfg.db.table +\n" +
  "    \" SET estado_flujo = '\" + esc(cfg.states.inProgress) + \"'\" +\n" +
  "    \", win_stamp = '\" + esc($json.win_stamp || '') + \"'\" +\n" +
  "    \", win_tries = win_tries + 1\" +\n" +
  "    \", telefono_index = telefono_index + 1\" +\n" +
  "    \", intentos_llamada = intentos_llamada + 1\" +\n" +
  "    \", fecha_ultima_llamada = now()\" +\n" +
  "    \", updated_at = now()\" +\n" +
  "    \" WHERE id_negocio = '\" + esc($json.id_negocio || '') + \"'\" +\n" +
  "    \" RETURNING *;\";\n" +
  "  return item;\n" +
  "});";

const newCodeNode = {
  parameters: { jsCode },
  type: 'n8n-nodes-base.code',
  typeVersion: 2,
  position: [capturaX + 260, capturaY],
  id: 'gen-sql-pre-llamada-001',
  name: 'GENERA SQL PRE-LLAMADA'
};

d.nodes.splice(d.nodes.indexOf(capturaNode) + 1, 0, newCodeNode);

const guardaPreLLamada = d.nodes.find(x => x.name === 'GUARDA PRE-LLAMADA');
guardaPreLLamada.parameters = {
  operation: 'executeQuery',
  query: '={{ $json.query }}',
  options: {}
};

d.connections['CAPTURA SNAPSHOT'] = {
  main: [[{ node: 'GENERA SQL PRE-LLAMADA', type: 'main', index: 0 }]]
};
d.connections['GENERA SQL PRE-LLAMADA'] = {
  main: [[{ node: 'GUARDA PRE-LLAMADA', type: 'main', index: 0 }]]
};

fs.writeFileSync(FILE, JSON.stringify(d, null, 2), 'utf8');

console.log('Done');
const v = JSON.parse(fs.readFileSync(FILE, 'utf8'));
const vn = v.nodes.find(x => x.name === 'GUARDA PRE-LLAMADA');
const gn = v.nodes.find(x => x.name === 'GENERA SQL PRE-LLAMADA');
console.log('GUARDA operation:', vn.parameters.operation);
console.log('GEN SQL exists:', !!gn);
