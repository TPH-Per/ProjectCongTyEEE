const fs = require('fs');

async function translateText(text, targetLang) {
  const url = `https://translate.googleapis.com/translate_a/single?client=gtx&sl=vi&tl=${targetLang}&dt=t&q=${encodeURIComponent(text)}`;
  try {
    const res = await fetch(url);
    const data = await res.json();
    return data[0].map(x => x[0]).join('');
  } catch (e) {
    console.error('Translation failed for', text, e);
    return text;
  }
}

async function main() {
  const extracted = JSON.parse(fs.readFileSync('extracted_from_vue.json', 'utf8'));
  const viFile = 'src/locales/vi.ts';
  const enFile = 'src/locales/en.ts';
  const jaFile = 'src/locales/ja.ts';

  const getExistingKeys = (file) => {
    const content = fs.readFileSync(file, 'utf8');
    const keys = new Set();
    const regex = /^\s*(auto_[a-zA-Z0-9_]+):/gm;
    let match;
    while ((match = regex.exec(content)) !== null) {
      keys.add(match[1]);
    }
    return { content, keys };
  };

  const viData = getExistingKeys(viFile);
  const enData = getExistingKeys(enFile);
  const jaData = getExistingKeys(jaFile);

  const missingKeys = Object.keys(extracted).filter(k => !viData.keys.has(k) || !enData.keys.has(k) || !jaData.keys.has(k));
  console.log(`Found ${missingKeys.length} missing keys.`);

  let viAdds = [];
  let enAdds = [];
  let jaAdds = [];

  for (let i = 0; i < missingKeys.length; i++) {
    const key = missingKeys[i];
    const viText = extracted[key];
    console.log(`Translating ${i+1}/${missingKeys.length}: ${viText}`);
    
    const enText = await translateText(viText, 'en');
    const jaText = await translateText(viText, 'ja');

    // Escape quotes
    const esc = (t) => t.replace(/'/g, "\\'");

    if (!viData.keys.has(key)) viAdds.push(`  ${key}: '${esc(viText)}',`);
    if (!enData.keys.has(key)) enAdds.push(`  ${key}: '${esc(enText)}',`);
    if (!jaData.keys.has(key)) jaAdds.push(`  ${key}: '${esc(jaText)}',`);
  }

  const appendToDefaultExport = (content, adds) => {
    if (adds.length === 0) return content;
    // Find the last closing brace of export default {
    const lastBraceIndex = content.lastIndexOf('}');
    if (lastBraceIndex === -1) return content; // safety

    const before = content.substring(0, lastBraceIndex);
    const after = content.substring(lastBraceIndex);

    // Make sure there is a trailing comma before appending
    let newBefore = before.trimEnd();
    if (!newBefore.endsWith(',')) {
      newBefore += ',';
    }

    return newBefore + '\n' + adds.join('\n') + '\n' + after;
  };

  if (viAdds.length > 0) fs.writeFileSync(viFile, appendToDefaultExport(viData.content, viAdds), 'utf8');
  if (enAdds.length > 0) fs.writeFileSync(enFile, appendToDefaultExport(enData.content, enAdds), 'utf8');
  if (jaAdds.length > 0) fs.writeFileSync(jaFile, appendToDefaultExport(jaData.content, jaAdds), 'utf8');

  console.log('Done!');
}

main();
