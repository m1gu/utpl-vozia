const fs = require('fs');
const s = fs.readFileSync('pruebas/leads_prueba.sql', 'utf8');
const lines = s.split('\n').filter(l => l.trim().startsWith("('SIM-"));
let badTel = 0, badWin = 0, badInt = 0;

lines.forEach(l => {
  const clean = l.trim().replace(/^\(/, '').replace(/\),?$/, '');
  const vals = [];
  let current = '', inQ = false;
  for (let i = 0; i < clean.length; i++) {
    const c = clean[i];
    if (c === "'" && clean[i + 1] === "'") { current += "'"; i++; }
    else if (c === "'") { inQ = !inQ; }
    else if (c === ',' && !inQ) { vals.push(current); current = ''; }
    else { current += c; }
  }
  vals.push(current);
  const col = (idx) => (vals[idx] || '').replace(/'/g, '').trim();

  const intentos = parseInt(col(13)) || 0;
  const win = parseInt(col(14)) || 0;
  const telRaw = col(18);
  const tel = telRaw === 'NULL' || telRaw === '' ? 0 : parseInt(telRaw) || 0;

  if (tel < 0 || tel > 6) { badTel++; if (badTel <= 3) console.log('BAD_TEL:', col(0), 'tel=' + tel, '| raw=' + telRaw); }
  if (win < 0 || win > 3) { badWin++; if (badWin <= 3) console.log('BAD_WIN:', col(0), 'win=' + win); }
  if (intentos < 0 || intentos > 16) { badInt++; if (badInt <= 3) console.log('BAD_INT:', col(0), 'int=' + intentos); }
});

console.log('telefono_index out of [0,6]: ' + badTel);
console.log('win_tries out of [0,3]:      ' + badWin);
console.log('intentos out of [0,16]:      ' + badInt);
console.log('total parsed: ' + lines.length);
