const fs = require('fs');

function mergeLocale(localeFile, translatedJsonFile) {
  let content = fs.readFileSync(localeFile, 'utf8');
  const translations = JSON.parse(fs.readFileSync(translatedJsonFile, 'utf8'));

  for (const [key, value] of Object.entries(translations)) {
    // Escape single quotes and backslashes in the value
    const escapedValue = value.replace(/\\/g, '\\\\').replace(/'/g, "\\'");
    // Replace the specific key in the locale file
    const regex = new RegExp(`(${key}:\\s*)['"](.*?)['"]`, 'g');
    content = content.replace(regex, `$1'${escapedValue}'`);
  }

  fs.writeFileSync(localeFile, content);
  console.log(`Merged ${Object.keys(translations).length} keys into ${localeFile}`);
}

mergeLocale('src/locales/en.ts', 'translated_en.json');
mergeLocale('src/locales/ja.ts', 'translated_ja.json');
