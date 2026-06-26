const fs = require('fs');
const path = require('path');

function walk(dir, fileList = []) {
  for (const file of fs.readdirSync(dir)) {
    const stat = fs.statSync(path.join(dir, file));
    if (stat.isDirectory()) walk(path.join(dir, file), fileList);
    else if (file.endsWith('.vue')) fileList.push(path.join(dir, file));
  }
  return fileList;
}

const vueFiles = walk(path.join(__dirname, 'src', 'views')).concat(walk(path.join(__dirname, 'src', 'layouts')));

const extracted = {};
// match t('auto_xyz', 'Default text') or $t('auto_xyz', 'Default text')
const regex = /\b(?:t|\$t)\(['"](auto_[^'"]+)['"],\s*['"]([^'"]+)['"]\)/g;

for (const file of vueFiles) {
  const content = fs.readFileSync(file, 'utf8');
  let match;
  while ((match = regex.exec(content)) !== null) {
    const key = match[1];
    const defaultText = match[2];
    extracted[key] = defaultText.replace(/\\'/g, "'");
  }
}

console.log('Extracted', Object.keys(extracted).length, 'keys from vue files');
fs.writeFileSync('extracted_from_vue.json', JSON.stringify(extracted, null, 2), 'utf8');
