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

const files = findFiles('src');
let changedCount = 0;

files.forEach(f => {
  let c = fs.readFileSync(f, 'utf8');
  const orig = c;
  
  // Replace $t('key', 'fallback') with $t('key')
  // We handle both single and double quotes for the second argument.
  // We also handle $t vs t
  
  // Pattern 1: $t('key', 'fallback')
  c = c.replace(/\$t\('([^']+)',\s*'[^']+'\)/g, "$$t('$1')");
  c = c.replace(/\$t\('([^']+)',\s*"[^"]+"\)/g, "$$t('$1')");
  
  // Pattern 2: t('key', 'fallback')
  c = c.replace(/\bt\('([^']+)',\s*'[^']+'\)/g, "t('$1')");
  c = c.replace(/\bt\('([^']+)',\s*"[^"]+"\)/g, "t('$1')");

  // Pattern 3: double quotes for key
  c = c.replace(/\$t\("([^"]+)",\s*'[^']+'\)/g, "$$t(\"$1\")");
  c = c.replace(/\$t\("([^"]+)",\s*"[^"]+"\)/g, "$$t(\"$1\")");
  c = c.replace(/\bt\("([^"]+)",\s*'[^']+'\)/g, "t(\"$1\")");
  c = c.replace(/\bt\("([^"]+)",\s*"[^"]+"\)/g, "t(\"$1\")");

  if (c !== orig) {
    fs.writeFileSync(f, c);
    changedCount++;
  }
});

console.log('Fixed ' + changedCount + ' vue files.');
