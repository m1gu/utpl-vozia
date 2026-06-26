const fs = require('fs');

const f = 'flujo_n8n/Utpl_CierreLlamadas.json';
const d = JSON.parse(fs.readFileSync(f, 'utf8'));
const n = d.nodes.find(x => x.name === 'GENERAR QUERY ACTUALIZA');

// Directly set the corrected jsCode
// The fix: change .replace(/'/g, ''') to .replace(/'/g, "''")
// In JSON, double quotes are escaped as \\"
n.parameters.jsCode = 
  "return items.map(item => {\n" +
  "  const cfg = $items('CONFIG INICIAL UTPL', 0, 0)[0].json.cfg;\n" +
  "  const raw = String(item.json.id_negocio ?? '').trim();\n" +
  "  if (!raw) {\n" +
  "    item.json.query = `SELECT 'skip_no_id_negocio' AS status`;\n" +
  "    return item;\n" +
  "  }\n" +
  "  const id_negocio = raw.replace(/'/g, \"''\");\n" +
  "  const estado = String(item.json.estado_flujo || cfg.states.done).replace(/'/g, \"''\");\n" +
  "  item.json.query = `\n" +
  "    UPDATE ${cfg.db.schema}.${cfg.db.table}\n" +
  "    SET estado_flujo = '${estado}',\n" +
  "        updated_at = now()\n" +
  "    WHERE id_negocio = '${id_negocio}'\n" +
  "    RETURNING *;\n" +
  "  `;\n" +
  "  return item;\n" +
  "});";

fs.writeFileSync(f, JSON.stringify(d, null, 2), 'utf8');

// Verify
const v = JSON.parse(fs.readFileSync(f, 'utf8'));
const vn = v.nodes.find(x => x.name === 'GENERAR QUERY ACTUALIZA');
console.log('Has triple quotes:', vn.parameters.jsCode.indexOf("'''") >= 0);
console.log(vn.parameters.jsCode);
