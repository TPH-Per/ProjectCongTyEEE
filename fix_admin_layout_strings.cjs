const fs = require('fs');

function replaceHardcodedAdminStrings() {
  const filePath = 'src/layouts/AdminLayout.vue';
  let content = fs.readFileSync(filePath, 'utf8');

  content = content.replace(/>System Admin</g, ">{{ t('auto_system_admin', 'System Admin') }}<");
  content = content.replace(/>Super User</g, ">{{ t('auto_super_user', 'Super User') }}<");
  content = content.replace(/alt="Avatar"/g, "alt=\"Avatar\""); // Keep as is, it's just an alt attribute

  fs.writeFileSync(filePath, content);

  // Append to locales
  for (const locale of ['vi', 'en', 'ja']) {
    let locContent = fs.readFileSync(`src/locales/${locale}.ts`, 'utf8');
    locContent = locContent.replace(/}\s*$/, `  auto_system_admin: 'System Admin',\n  auto_super_user: 'Super User',\n}`);
    fs.writeFileSync(`src/locales/${locale}.ts`, locContent);
  }
}

replaceHardcodedAdminStrings();
