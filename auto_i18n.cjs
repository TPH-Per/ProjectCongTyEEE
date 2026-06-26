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

const vnRegex = /([ \n\t]*)([^<]*[àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹĐđ]+[^<]*)([ \n\t]*)/;

function generateKey(text) {
  let key = text.trim()
    .toLowerCase()
    .normalize("NFD").replace(/[\u0300-\u036f]/g, "") // remove accents
    .replace(/đ/g, 'd')
    .replace(/[^a-z0-9]/g, '_')
    .replace(/_+/g, '_')
    .substring(0, 30);
  return 'auto_' + key.replace(/^_|_$/g, '');
}

const newKeys = {};

for (const file of vueFiles) {
  let content = fs.readFileSync(file, 'utf8');
  let modified = false;

  const templateMatch = content.match(/<template>([\s\S]*?)<\/template>/);
  if (templateMatch) {
    let template = templateMatch[1];
    
    // Replace text nodes
    template = template.replace(/>([^<]+)</g, (match, text) => {
      if (text.includes('{{') || text.includes('t(')) return match; // skip if it already contains expressions
      
      const m = text.match(vnRegex);
      if (m && m[2].trim().length > 0) {
        const originalText = m[2].trim();
        // Ignore single characters or very short non-word strings
        if (originalText.length < 2) return match;
        
        const key = generateKey(originalText);
        newKeys[key] = originalText;
        
        return `>${m[1]}{{ $t('${key}', '${originalText.replace(/'/g, "\\'")}') }}${m[3]}<`;
      }
      return match;
    });

    // Replace attributes (not starting with :)
    template = template.replace(/\bplaceholder="([^"]*)"/gi, (match, text) => {
        if (text.includes('t(')) return match;
        const m = text.match(vnRegex);
        if(m) {
            const key = generateKey(text);
            newKeys[key] = text;
            return `:placeholder="$t('${key}', '${text.replace(/'/g, "\\'")}')"`;
        }
        return match;
    });

    template = template.replace(/\btitle="([^"]*)"/gi, (match, text) => {
        if (text.includes('t(')) return match;
        const m = text.match(vnRegex);
        if(m) {
            const key = generateKey(text);
            newKeys[key] = text;
            return `:title="$t('${key}', '${text.replace(/'/g, "\\'")}')"`;
        }
        return match;
    });

    if (template !== templateMatch[1]) {
      content = content.replace(templateMatch[1], template);
      modified = true;
    }
  }

  if (modified) {
    fs.writeFileSync(file, content);
    console.log('Updated', file);
  }
}

fs.writeFileSync('new_extracted_keys.json', JSON.stringify(newKeys, null, 2));
console.log('Extracted', Object.keys(newKeys).length, 'new keys');
