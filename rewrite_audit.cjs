const fs = require('fs');

let content = fs.readFileSync('src/views/admin/AdminAuditView.vue', 'utf8');

// Replace Hệ thống
content = content.replace(/log\.branches\?\.name \|\| 'Hệ thống'/g, "log.branches?.name || t('auto_he_thong')");
content = content.replace(/log\.users\?\.full_name \|\| 'Hệ thống'/g, "log.users?.full_name || t('auto_he_thong')");

// In case the `cat` showed `H? th?ng`, let's just use regex
content = content.replace(/log\.branches\?\.name \|\| 'H\? th\?ng'/g, "log.branches?.name || t('auto_he_thong')");
content = content.replace(/log\.users\?\.full_name \|\| 'H\? th\?ng'/g, "log.users?.full_name || t('auto_he_thong')");

// Fix the template action part to format it beautifully
const actionSpan = `
                <span :class="{
                  'px-3 py-1 rounded-full text-[11px] font-bold tracking-wide uppercase': true,
                  'bg-green-100/80 text-green-700 border border-green-200': formatActionColor(log.action) === 'green',
                  'bg-blue-100/80 text-blue-700 border border-blue-200': formatActionColor(log.action) === 'blue',
                  'bg-red-100/80 text-red-700 border border-red-200': formatActionColor(log.action) === 'red',
                  'bg-purple-100/80 text-purple-700 border border-purple-200': formatActionColor(log.action) === 'purple'
                }">
                  {{ formatActionText(log.action) }}
                </span>
`;
// Replace the old span
content = content.replace(/<span :class="\{[\s\S]*?\}">\s*\{\{ log\.action \}\}\s*<\/span>/m, actionSpan);


// Fix the payload part to format JSON nicer
const payloadDiv = `
                <div class="bg-gray-50/80 p-2.5 rounded-xl text-xs text-gray-600 max-h-32 overflow-y-auto border border-gray-200/60 shadow-inner">
                  <div v-if="log.payload && typeof log.payload === 'object'">
                    <div v-for="(val, key) in flattenPayload(log.payload)" :key="key" class="mb-1 border-b border-gray-100/50 pb-1 last:border-0 last:pb-0">
                      <span class="font-bold text-gray-700">{{ key }}:</span>
                      <span class="ml-1 text-gray-500">{{ val }}</span>
                    </div>
                  </div>
                  <pre v-else class="whitespace-pre-wrap break-words font-mono text-[10px]">{{ log.payload }}</pre>
                </div>
`;
content = content.replace(/<div class="bg-gray-50\/80 p-2\.5 rounded-xl text-xs text-gray-600 max-h-32 overflow-y-auto border border-gray-200\/60 shadow-inner">[\s\S]*?<\/div>/m, payloadDiv);


// Inject methods into script setup
const scriptMethods = `
const formatActionColor = (action: string) => {
  const act = action.toLowerCase();
  if (act.includes('create') || act.includes('insert')) return 'green';
  if (act.includes('update')) return 'blue';
  if (act.includes('delete')) return 'red';
  return 'purple';
};

const formatActionText = (action: string) => {
  // Convert 'table_assignment.created' to 'Tạo table_assignment' 
  // Normally we'd fully translate, but for audit let's make it look cleaner.
  if (!action) return 'UNKNOWN';
  if (action.includes('.')) {
    const parts = action.split('.');
    const entity = parts[0].replace(/_/g, ' ');
    const verb = parts[1];
    
    let translatedVerb = verb;
    if (verb === 'created' || verb === 'insert') translatedVerb = t('auto_t_o_m_i__create_');
    else if (verb === 'updated') translatedVerb = t('auto_c_p_nh_t__update_');
    else if (verb === 'deleted') translatedVerb = t('auto_x_a__delete_');
    
    return \`\${translatedVerb} \${entity}\`;
  }
  return action;
};

const flattenPayload = (payload: any) => {
  if (!payload) return {};
  // if payload has 'after', use that instead
  const data = payload.after ? payload.after : payload;
  const result: Record<string, string> = {};
  for (const key in data) {
    if (typeof data[key] === 'object' && data[key] !== null) {
      result[key] = JSON.stringify(data[key]);
    } else {
      result[key] = String(data[key] ?? 'null');
    }
  }
  return result;
};
`;

content = content.replace(/(const filteredLogs = computed\(\(\) => \{)/, `${scriptMethods}\n\n$1`);

fs.writeFileSync('src/views/admin/AdminAuditView.vue', content);
