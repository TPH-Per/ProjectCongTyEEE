const fs = require('fs');

async function translateText(text, targetLang) {
  const url = `https://translate.googleapis.com/translate_a/single?client=gtx&sl=vi&tl=${targetLang}&dt=t&q=${encodeURIComponent(text)}`;
  try {
    const res = await fetch(url);
    const data = await res.json();
    return data[0].map(x => x[0]).join('');
  } catch (e) {
    console.error('Translation failed for', text.substring(0, 20), e);
    return text;
  }
}

async function main() {
  const viFile = 'src/locales/vi.ts';
  const enFile = 'src/locales/en.ts';
  const jaFile = 'src/locales/ja.ts';

  const getExistingKeys = (file) => {
    const content = fs.readFileSync(file, 'utf8');
    const map = new Map();
    const regex = /^\s*'?([a-zA-Z0-9_]+)'?:\s*'([^']+)',?/gm;
    let match;
    while ((match = regex.exec(content)) !== null) {
      map.set(match[1], match[2]);
    }
    return { content, map };
  };

  const viData = getExistingKeys(viFile);
  const enData = getExistingKeys(enFile);
  const jaData = getExistingKeys(jaFile);

  const missingKeys = [];
  for (const [k, v] of viData.map.entries()) {
    if (!enData.map.has(k) || !jaData.map.has(k)) {
      missingKeys.push(k);
    }
  }

  console.log(`Found ${missingKeys.length} missing keys.`);

  let enAdds = [];
  let jaAdds = [];

  const chunkSize = 20;
  for (let i = 0; i < missingKeys.length; i += chunkSize) {
    const chunkKeys = missingKeys.slice(i, i + chunkSize);
    const chunkTexts = chunkKeys.map(k => viData.map.get(k));
    console.log(`Translating batch ${i} to ${i + chunkKeys.length}...`);
    
    const combinedText = chunkTexts.join(' ||| ');
    
    let enCombined = await translateText(combinedText, 'en');
    let jaCombined = await translateText(combinedText, 'ja');
    
    const enTexts = enCombined.split(/\s*\|\|\|\s*/).map(t => t.trim());
    const jaTexts = jaCombined.split(/\s*\|\|\|\s*/).map(t => t.trim());

    for (let j = 0; j < chunkKeys.length; j++) {
      const key = chunkKeys[j];
      const viText = chunkTexts[j];
      const enText = enTexts[j] || viText;
      const jaText = jaTexts[j] || viText;

      const esc = (t) => t.replace(/'/g, "\\'");

      if (!enData.map.has(key)) enAdds.push(`  '${key}': '${esc(enText)}',`);
      if (!jaData.map.has(key)) jaAdds.push(`  '${key}': '${esc(jaText)}',`);
    }
  }

  const appendToDefaultExport = (content, adds) => {
    if (adds.length === 0) return content;
    const lastBraceIndex = content.lastIndexOf('}');
    if (lastBraceIndex === -1) return content;

    const before = content.substring(0, lastBraceIndex);
    const after = content.substring(lastBraceIndex);

    let newBefore = before.trimEnd();
    if (!newBefore.endsWith(',')) newBefore += ',';

    return newBefore + '\n' + adds.join('\n') + '\n' + after;
  };

  if (enAdds.length > 0) fs.writeFileSync(enFile, appendToDefaultExport(enData.content, enAdds), 'utf8');
  if (jaAdds.length > 0) fs.writeFileSync(jaFile, appendToDefaultExport(jaData.content, jaAdds), 'utf8');

  console.log('Done!');
}

main();
