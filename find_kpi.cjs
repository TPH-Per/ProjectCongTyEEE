const fs = require('fs');
const path = require('path');

function findHardcoded(dir) {
  const files = fs.readdirSync(dir);
  for (const file of files) {
    const fullPath = path.join(dir, file);
    if (fs.statSync(fullPath).isDirectory()) {
      findHardcoded(fullPath);
    } else if (fullPath.endsWith('.vue')) {
      const content = fs.readFileSync(fullPath, 'utf8');
      if (content.includes('Doanh Thu') || content.includes('COGS')) {
        console.log(`Found in ${fullPath}`);
      }
    }
  }
}

findHardcoded('src/views');
