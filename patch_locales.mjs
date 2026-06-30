import fs from 'fs';

const storeContent = fs.readFileSync('src/stores/useLanguageStore.ts', 'utf-8');

const regexVi = /vi:\s*{([\s\S]*?)},\s*en:/;
const regexEn = /en:\s*{([\s\S]*?)},\s*ja:/;
const regexJa = /ja:\s*{([\s\S]*?)}\s*};/;

const extractKeys = (content, regex) => {
  const match = content.match(regex);
  if (!match) return {};
  const block = match[1];
  const lines = block.split('\n');
  const dict = {};
  for (const line of lines) {
    const m = line.match(/^\s*'([^']+)':\s*'([^']*)'/);
    if (m) {
      if (m[1].startsWith('reception.')) {
        dict[m[1]] = m[2];
      }
    }
  }
  return dict;
};

const viKeys = extractKeys(storeContent, regexVi);
const enKeys = extractKeys(storeContent, regexEn);
const jaKeys = extractKeys(storeContent, regexJa);

console.log(`Found ${Object.keys(viKeys).length} reception keys in vi`);

const injectLocales = (file, newKeys) => {
  let content = fs.readFileSync(file, 'utf-8');
  let newObjStr = '';
  for (const [k, v] of Object.entries(newKeys)) {
    newObjStr += `  '${k}': '${v}',\n`;
  }
  // insert before the last brace
  content = content.replace(/}\s*$/, `${newObjStr}}\n`);
  fs.writeFileSync(file, content);
};

injectLocales('src/locales/vi.ts', viKeys);
injectLocales('src/locales/en.ts', enKeys);
injectLocales('src/locales/ja.ts', jaKeys);

console.log('Injected reception keys into vue-i18n locales');
