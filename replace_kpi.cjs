const fs = require('fs');
const path = require('path');

function replaceHardcoded(dir) {
  const files = fs.readdirSync(dir);
  for (const file of files) {
    const fullPath = path.join(dir, file);
    if (fs.statSync(fullPath).isDirectory()) {
      replaceHardcoded(fullPath);
    } else if (fullPath.endsWith('.vue')) {
      let content = fs.readFileSync(fullPath, 'utf8');
      let changed = false;
      if (content.includes('>Doanh Thu<')) {
        content = content.replace(/>Doanh Thu</g, ">{{ t('auto_doanh_thu') }}<");
        changed = true;
      }
      if (content.includes('>COGS<')) {
        content = content.replace(/>COGS</g, ">{{ t('auto_cogs') }}<");
        changed = true;
      }
      if (changed) {
        fs.writeFileSync(fullPath, content);
        console.log(`Updated ${fullPath}`);
      }
    }
  }
}

replaceHardcoded('src/views');
