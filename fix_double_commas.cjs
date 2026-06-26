const fs = require('fs');

const fixCommas = (file) => {
  let content = fs.readFileSync(file, 'utf8');
  content = content.replace(/,,/g, ',');
  fs.writeFileSync(file, content, 'utf8');
}

fixCommas('src/locales/en.ts');
fixCommas('src/locales/ja.ts');
fixCommas('src/locales/vi.ts');
console.log('Fixed double commas');
