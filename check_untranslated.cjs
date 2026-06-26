const fs = require('fs');

const viStr = fs.readFileSync('src/locales/vi.ts', 'utf8');
const enStr = fs.readFileSync('src/locales/en.ts', 'utf8');

const keyValRegex = /(auto_[a-zA-Z0-9_]+):\s*(['"])(.*?)\2/g;

let match;
const enDict = {};
while ((match = keyValRegex.exec(enStr)) !== null) {
  enDict[match[1]] = match[3];
}

const untranslated = [];
while ((match = keyValRegex.exec(viStr)) !== null) {
  const key = match[1];
  const viVal = match[3];
  if (enDict[key] === viVal) {
    untranslated.push({ key, viVal });
  }
}

console.log(`Found ${untranslated.length} untranslated keys.`);
console.log(untranslated.slice(0, 20));
