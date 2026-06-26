const fs = require('fs');
const path = require('path');

function getFiles(dir) {
  let results = [];
  fs.readdirSync(dir).forEach(file => {
    let p = path.join(dir, file);
    if (fs.statSync(p).isDirectory()) results = results.concat(getFiles(p));
    else if (p.endsWith('.vue')) results.push(p);
  });
  return results;
}

const vueFiles = getFiles('src/views');

vueFiles.forEach(f => {
  let c = fs.readFileSync(f, 'utf8');
  let originalC = c;
  
  // Fix ::placeholder="$t('...', '\n t('...', 'TEXT')\n ')"
  const badPlaceholderRegex = /::placeholder="\$t\('auto_t_auto_[^']+',\s*'[\s\n]*t\('auto_[^']+',\s*'([^']+)'\)[ \n]*'\)"/gs;
  c = c.replace(badPlaceholderRegex, ':placeholder="$t(\'auto_placeholder_fix\', \'$1\')"');

  // Fix ::title="$t('...', '\n t('...', 'TEXT')\n ')"
  const badTitleRegex = /::title="\$t\('auto_t_auto_[^']+',\s*'[\s\n]*t\('auto_[^']+',\s*'([^']+)'\)[ \n]*'\)"/gs;
  c = c.replace(badTitleRegex, ':title="$t(\'auto_title_fix\', \'$1\')"');
  
  // Sometimes it's just ::placeholder="$t('...', ' t('...', 'TEXT') ')"
  // Already caught by \s*

  if (c !== originalC) {
    fs.writeFileSync(f, c);
    console.log('Fixed', f);
  }
});
