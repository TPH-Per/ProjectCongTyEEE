const fs = require('fs');

// Fix AdminLayout.vue
let adminLayout = fs.readFileSync('src/layouts/AdminLayout.vue', 'utf8');
adminLayout = adminLayout.replace(/\{\{\s*t\('auto_system_admin/g, "{{ $t('auto_system_admin");
adminLayout = adminLayout.replace(/\{\{\s*t\('auto_super_user/g, "{{ $t('auto_super_user");
fs.writeFileSync('src/layouts/AdminLayout.vue', adminLayout);

// Remove duplicate keys in locales
for (const locale of ['en', 'ja', 'vi']) {
  let content = fs.readFileSync(`src/locales/${locale}.ts`, 'utf8');
  
  // A simple way to remove duplicate keys from the end of the file is to split into lines
  const lines = content.split('\n');
  const seen = new Set();
  const newLines = [];
  
  for (let i = lines.length - 1; i >= 0; i--) {
    const line = lines[i];
    const match = line.match(/^\s*(auto_[a-zA-Z0-9_]+):/);
    if (match) {
      if (seen.has(match[1])) {
        continue; // duplicate key found, skip
      }
      seen.add(match[1]);
    }
    newLines.unshift(line);
  }
  
  fs.writeFileSync(`src/locales/${locale}.ts`, newLines.join('\n'));
}

