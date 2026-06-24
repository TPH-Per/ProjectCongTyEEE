const fs = require('fs');
const path = require('path');

const funcDir = 'C:/Users/Per/Downloads/noMoreF2TECH/supabase/functions';
const items = fs.readdirSync(funcDir);

items.forEach(item => {
  const dirPath = path.join(funcDir, item);
  if (fs.statSync(dirPath).isDirectory() && item !== '_shared') {
    const indexPath = path.join(dirPath, 'index.ts');
    if (fs.existsSync(indexPath)) {
      let content = fs.readFileSync(indexPath, 'utf8');
      
      // Remove corsHeaders from auth.ts import
      content = content.replace(/import\s+{\s*([^}]*?)\s*}\s+from\s+['"]\.\.\/_shared\/auth\.ts['"]/g, (match, p1) => {
        let imports = p1.split(',').map(s => s.trim()).filter(s => s !== 'corsHeaders' && s.length > 0);
        if (imports.length === 0) return '';
        return `import { ${imports.join(', ')} } from '../_shared/auth.ts'`;
      });
      
      // Add corsHeaders import if missing and used
      if (content.includes('corsHeaders') && !content.includes('../_shared/cors.ts')) {
        const lines = content.split('\n');
        let lastImportIdx = -1;
        for(let i=0; i<lines.length; i++) {
          if (lines[i].startsWith('import ')) lastImportIdx = i;
        }
        if (lastImportIdx !== -1) {
          lines.splice(lastImportIdx + 1, 0, `import { corsHeaders } from '../_shared/cors.ts'`);
          content = lines.join('\n');
        } else {
          content = `import { corsHeaders } from '../_shared/cors.ts'\n` + content;
        }
      }
      
      fs.writeFileSync(indexPath, content);
    }
  }
});
console.log('Fixed imports');
