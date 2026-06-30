import fs from 'fs';

const files = [
  'src/views/reception/ReceptionDashboardView.vue'
];

let allKeys = new Set();

files.forEach(file => {
  const content = fs.readFileSync(file, 'utf-8');
  const regex = /\$?t\(['"](reception\.dashboard\.[a-zA-Z0-9_]+)['"]/g;
  let match;
  while ((match = regex.exec(content)) !== null) {
    allKeys.add(match[1]);
  }
});

console.log('Found ' + allKeys.size + ' dashboard keys');
fs.writeFileSync('missing_dashboard_keys.json', JSON.stringify(Array.from(allKeys), null, 2));
