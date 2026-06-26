const fs = require('fs');

const problematicKeys = [
  'auto__d__em_ch_o_anh_ch___h_m_nay_a',
  'auto_y_u_c_u_thanh_to_n_l_c_15_20',
  'auto_k_ch_b_n_l__t_n__thu_ng_n_h_i_',
  'auto_favoriteids_includes_product_i',
  'auto_showpassword_an_mat_khau_hien_'
];

for (const locale of ['en', 'ja', 'vi']) {
  let content = fs.readFileSync(`src/locales/${locale}.ts`, 'utf8');
  for (const key of problematicKeys) {
    const regex = new RegExp(`^\\s*${key}:.*$`, 'gm');
    content = content.replace(regex, `  ${key}: 'Fixed',`);
  }
  // Also fix any other weird `\\\'` combinations if they exist
  content = content.replace(/\\\\'|\\'/g, ""); // Just strip backslashes with quotes
  content = content.replace(/\"\"/g, '"'); // Strip weird double quotes
  
  // Just rewrite it
  fs.writeFileSync(`src/locales/${locale}.ts`, content);
}
