const fs = require('fs');
const path = require('path');

function findFiles(dir) {
  let results = [];
  const list = fs.readdirSync(dir);
  list.forEach(file => {
    file = path.join(dir, file);
    const stat = fs.statSync(file);
    if (stat && stat.isDirectory()) { 
      results = results.concat(findFiles(file));
    } else if (file.endsWith('.vue')) {
      results.push(file);
    }
  });
  return results;
}

const viContent = fs.readFileSync('src/locales/vi.ts', 'utf8');
const files = findFiles('src');
const missingKeys = new Set();

files.forEach(f => {
  const c = fs.readFileSync(f, 'utf8');
  const regex = /(?:\$t|t)\(['"]([^'"]+)['"]/g;
  let match;
  while ((match = regex.exec(c)) !== null) {
    const key = match[1];
    if (key.startsWith('auto_')) {
      if (!viContent.includes(key + ':') && !viContent.includes("'" + key + "':")) {
         missingKeys.add(key);
      }
    }
  }
});
console.log('Missing keys:', Array.from(missingKeys));
