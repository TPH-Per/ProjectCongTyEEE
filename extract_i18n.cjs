const fs = require('fs');
const path = require('path');

function walk(dir, fileList = []) {
  const files = fs.readdirSync(dir);
  for (const file of files) {
    const stat = fs.statSync(path.join(dir, file));
    if (stat.isDirectory()) {
      walk(path.join(dir, file), fileList);
    } else if (file.endsWith('.vue')) {
      fileList.push(path.join(dir, file));
    }
  }
  return fileList;
}

const vueFiles = walk(path.join(__dirname, 'src', 'views')).concat(walk(path.join(__dirname, 'src', 'layouts')));

const extracted = {};

const regex = /\$?t\(\s*['"]([^'"]+)['"]\s*,\s*['"]([^'"]+)['"]\s*\)/g;

for (const file of vueFiles) {
  const content = fs.readFileSync(file, 'utf8');
  let match;
  while ((match = regex.exec(content)) !== null) {
    const key = match[1];
    const defaultText = match[2];
    extracted[key] = defaultText;
  }
}

fs.writeFileSync('extracted_keys.json', JSON.stringify(extracted, null, 2));
console.log('Extracted', Object.keys(extracted).length, 'keys');
