import fs from 'fs';

const storeContent = fs.readFileSync('src/stores/useLanguageStore.ts', 'utf-8');
const viBlockMatch = storeContent.match(/vi:\s*{([\s\S]*?)},\s*en:/);
if (!viBlockMatch) { console.log('No vi block'); process.exit(1); }

const lines = viBlockMatch[1].split('\n');
let count = 0;
let firstFew = [];
for (const line of lines) {
  const m = line.match(/^\s*'([^']+)':/);
  if (m) {
    count++;
    if (firstFew.length < 10) firstFew.push(m[1]);
  }
}
console.log(`Total keys in vi dict: ${count}`);
console.log(`First few: ${firstFew.join(', ')}`);
