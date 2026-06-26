const fs = require('fs');
const path = require('path');

const d = JSON.parse(fs.readFileSync(path.join(__dirname,'..','flujo_n8n','Utpl_Llamadas.json'), 'utf8'));
const n = d.nodes.find(x => x.name === 'GUARDA REPORTE');

n.parameters = {
  operation: 'upsert',
  schema: { __rl: true, mode: 'list', value: 'public' },
  table: { __rl: true, mode: 'list', value: 'utpl_registros', cachedResultName: 'utpl_registros' },
  columns: {
    mappingMode: 'defineBelow',
    value: {
      "id_negocio": "={{ String($json.id_negocio || '') }}",
      "cedula": "={{ String($json.cedula || '') }}",
      "estado_flujo": "={{ $json.estado_flujo || $items('CONFIG INICIAL UTPL', 0, 0)[0].json.cfg.states.done }}",
      "fecha_reagenda": "={{ $json.fecha_reagenda }}",
      "intentos_llamada": "={{ Number($json.intentos_llamada || 0) }}",
      "win_tries": "={{ Number($json.win_tries || 0) }}",
      "telefono_index": "={{ Number($json.telefono_index || 0) }}",
      "updated_at": "={{ $now }}"
    },
    matchingColumns: ['id_negocio'],
    schema: [
      { id: 'cedula', displayName: 'cedula', required: true, defaultMatch: false, display: true, type: 'string', canBeUsedToMatch: true },
      { id: 'estado_flujo', displayName: 'estado_flujo', required: false, defaultMatch: false, display: true, type: 'string', canBeUsedToMatch: false },
      { id: 'fecha_reagenda', displayName: 'fecha_reagenda', required: false, defaultMatch: false, display: true, type: 'dateTime', canBeUsedToMatch: false },
      { id: 'win_stamp', displayName: 'win_stamp', required: false, defaultMatch: false, display: true, type: 'string', canBeUsedToMatch: false },
      { id: 'win_tries', displayName: 'win_tries', required: false, defaultMatch: false, display: true, type: 'number', canBeUsedToMatch: false },
      { id: 'intentos_llamada', displayName: 'intentos_llamada', required: false, defaultMatch: false, display: true, type: 'number', canBeUsedToMatch: false },
      { id: 'telefono_index', displayName: 'telefono_index', required: false, defaultMatch: false, display: true, type: 'number', canBeUsedToMatch: false },
      { id: 'created_at', displayName: 'created_at', required: false, defaultMatch: false, display: true, type: 'dateTime', canBeUsedToMatch: false },
      { id: 'updated_at', displayName: 'updated_at', required: false, defaultMatch: false, display: true, type: 'dateTime', canBeUsedToMatch: false },
      { id: 'fecha_ultima_llamada', displayName: 'fecha_ultima_llamada', required: false, defaultMatch: false, display: true, type: 'dateTime', canBeUsedToMatch: false }
    ]
  },
  options: {}
};

fs.writeFileSync(path.join(__dirname,'..','flujo_n8n','Utpl_Llamadas.json'), JSON.stringify(d, null, 2), 'utf8');

const v = JSON.parse(fs.readFileSync(path.join(__dirname,'..','flujo_n8n','Utpl_Llamadas.json'), 'utf8'));
const vn = v.nodes.find(x => x.name === 'GUARDA REPORTE');
console.log('Operation:', vn.parameters.operation);
console.log('Has id_negocio in value:', vn.parameters.columns && vn.parameters.columns.value && !!vn.parameters.columns.value.id_negocio);
