import fs from 'fs';

const storeContent = fs.readFileSync('src/stores/useLanguageStore.ts', 'utf-8');
const keys = JSON.parse(fs.readFileSync('reception_keys.json', 'utf-8'));

// Find missing keys
let missingKeys = [];
for (const key of keys) {
  if (!storeContent.includes(`"${key}"`) && !storeContent.includes(`'${key}'`)) {
    missingKeys.push(key);
  }
}

console.log('Missing keys:', missingKeys.length);
fs.writeFileSync('missing_reception_keys.json', JSON.stringify(missingKeys, null, 2));
