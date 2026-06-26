const fs = require('fs');
const d = JSON.parse(fs.readFileSync('flujo_n8n/Utpl_CierreLlamadas.json', 'utf8'));
const n = d.nodes.find(x => x.name === 'GENERAR QUERY ACTUALIZA');
const js = n.parameters.jsCode;
console.log('Has triple single quotes:', js.indexOf("'''") >= 0);
console.log('Full code:');
console.log(js);
