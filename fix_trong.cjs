const fs = require('fs');
let c = fs.readFileSync('src/views/admin/AdminFloorsView.vue', 'utf8');

c = c.replace(
  /\{\{\s*stats\.availableTables\s*\}\}\/\{\{\s*stats\.totalTables\s*\}\}\s*trống/g,
  `{{ stats.availableTables }}/{{ stats.totalTables }} {{ t('auto_trong_nho', 'trống') }}`
);

c = c.replace(
  /\{\{\s*stats\.availableSeats\s*\}\}\/\{\{\s*stats\.totalSeats\s*\}\}\s*trống/g,
  `{{ stats.availableSeats }}/{{ stats.totalSeats }} {{ t('auto_trong_nho', 'trống') }}`
);

// Also look for `{{ t("auto_thi_t_l_p_tr_ng", "Đã Thiết lập Trống") }}` which is weird
c = c.replace(
  /\{\{\s*t\("auto_thi_t_l_p_tr_ng",\s*"Đã Thiết lập Trống"\)\s*\}\}/g,
  `{{ t("auto_thi_t_l_p_tr_ng", "Thiết lập Trống") }}`
);

fs.writeFileSync('src/views/admin/AdminFloorsView.vue', c, 'utf8');
console.log('Fixed trống tags');
