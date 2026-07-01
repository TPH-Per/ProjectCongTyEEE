const fs = require('fs');
const path = require('path');

function walk(dir) {
  let results = [];
  try {
    const list = fs.readdirSync(dir);
    list.forEach(file => {
      file = path.join(dir, file);
      const stat = fs.statSync(file);
      if (stat && stat.isDirectory()) {
        results = results.concat(walk(file));
      } else if (file.endsWith('.vue')) {
        results.push(file);
      }
    });
  } catch (err) {
    // ignore
  }
  return results;
}

const views = walk('src/views');
const outPath = 'output_scripts.txt';
fs.writeFileSync(outPath, '');

views.forEach(file => {
  const content = fs.readFileSync(file, 'utf8');
  const match = content.match(/<script.*?setup.*?>([\s\S]*?)<\/script>/);
  if (match) {
    fs.appendFileSync(outPath, `\n\n=================================\nFILE: ${file}\n=================================\n`);
    fs.appendFileSync(outPath, match[1]);
  }
});
