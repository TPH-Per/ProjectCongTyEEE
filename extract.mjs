import fs from 'fs';

const files = [
  'src/views/reception/ReceptionCheckoutView.vue',
  'src/views/reception/ReceptionCloseShiftView.vue',
  'src/views/reception/ReceptionOrderView.vue'
];

let allKeys = new Set();

files.forEach(file => {
  const content = fs.readFileSync(file, 'utf-8');
  const regex = /\$?t\(['"](reception\.checkout\.[a-zA-Z0-9_]+|reception\.close_shift\.[a-zA-Z0-9_]+|reception_order\.[a-zA-Z0-9_]+)['"]/g;
  let match;
  while ((match = regex.exec(content)) !== null) {
    allKeys.add(match[1]);
  }
});

console.log('Found ' + allKeys.size + ' keys');
fs.writeFileSync('reception_keys.json', JSON.stringify(Array.from(allKeys), null, 2));
