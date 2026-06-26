const fs = require('fs');

function fixLine() {
  for (const locale of ['en', 'ja']) {
    let content = fs.readFileSync(`src/locales/${locale}.ts`, 'utf8');
    // We just remove the problematic line or fix it.
    // The key is auto_showpassword_an_mat_khau_hien_
    content = content.replace(/auto_showpassword_an_mat_khau_hien_:.*?,/g, "auto_showpassword_an_mat_khau_hien_: 'Toggle Password',");
    fs.writeFileSync(`src/locales/${locale}.ts`, content);
  }
}

fixLine();
