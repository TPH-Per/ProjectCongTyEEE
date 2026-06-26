const fs = require('fs');

function removeDuplicates(file) {
  let content = fs.readFileSync(file, 'utf8');
  let lines = content.split('\n');
  let seenKeys = new Set();
  let newLines = [];

  for (let i = lines.length - 1; i >= 0; i--) {
    let line = lines[i];
    let match = line.match(/^\s*['"]?([a-zA-Z0-9_]+)['"]?\s*:/);
    if (match) {
      let key = match[1];
      if (seenKeys.has(key)) {
        console.log('Removing duplicate key ' + key + ' from ' + file);
        continue;
      }
      seenKeys.add(key);
    }
    newLines.push(line);
  }

  fs.writeFileSync(file, newLines.reverse().join('\n'), 'utf8');
}

removeDuplicates('src/locales/en.ts');
removeDuplicates('src/locales/ja.ts');
removeDuplicates('src/locales/vi.ts');
console.log('Deduplication done.');
