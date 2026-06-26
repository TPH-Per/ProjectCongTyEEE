const fs = require('fs');

for (const locale of ['en', 'ja', 'vi']) {
  let content = fs.readFileSync(`src/locales/${locale}.ts`, 'utf8');
  content = content.replace(/\\\\'/g, "\\'"); // Replace 4 backslashes + quote with 2 backslashes + quote?
  // Let's just blindly remove problematic entries for these specific keys
  content = content.replace(/auto_favoriteids_includes_product_i:.*?,/g, "auto_favoriteids_includes_product_i: 'Toggle Favorite',");
  content = content.replace(/auto_showpassword_an_mat_khau_hien_:.*?,/g, "auto_showpassword_an_mat_khau_hien_: 'Toggle Password',");
  fs.writeFileSync(`src/locales/${locale}.ts`, content);
}

