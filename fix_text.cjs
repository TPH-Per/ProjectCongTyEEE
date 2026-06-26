const fs = require('fs');
let content = fs.readFileSync('src/views/admin/AdminFloorsView.vue', 'utf8');

content = content.replace(
  />Sức chứa: \{\{ table\.capacity \}\} ghế<\/span/g,
  `>{{ t('auto_suc_chua') }} {{ table.capacity }} {{ t('auto_ghe', 'ghế') }}</span`
);

content = content.replace(
  /<span>👥 \{\{ table\.capacity \}\} khách<\/span>/g,
  `<span>👥 {{ table.capacity }} {{ t('auto_khach', 'khách') }}</span>`
);

content = content.replace(
  />\{\{ selectedTableForModal\.capacity \}\} ghế ngồi<\/span/g,
  `>{{ selectedTableForModal.capacity }} {{ t('auto_ghe_ngoi', 'ghế ngồi') }}</span`
);

content = content.replace(
  /\{\{ tbl\.code \}\} \(Sức chứa: \{\{ tbl\.capacity \}\} chỗ\)/g,
  `{{ tbl.code }} ({{ t('auto_suc_chua') }} {{ tbl.capacity }} {{ t('auto_cho', 'chỗ') }})`
);

content = content.replace(
  /Bàn \{\{ tbl\.code \}\} \(\{\{ tbl\.capacity \}\} ghế\)/g,
  `{{ t('auto_ban') }} {{ tbl.code }} ({{ tbl.capacity }} {{ t('auto_ghe', 'ghế') }})`
);

content = content.replace(
  /Bàn \{\{ tbl\.code \}\} \(Chỗ ngồi: \{\{ tbl\.capacity \}\} ghế\) -/g,
  `{{ t('auto_ban') }} {{ tbl.code }} ({{ t('auto_cho_ngoi', 'Chỗ ngồi') }}: {{ tbl.capacity }} {{ t('auto_ghe', 'ghế') }}) -`
);

content = content.replace(
  /Chi Tiết Bàn \{\{ selectedTableForModal\.code \}\}/g,
  `{{ t('auto_chi_tiet_ban', 'Chi Tiết Bàn') }} {{ selectedTableForModal.code }}`
);

fs.writeFileSync('src/views/admin/AdminFloorsView.vue', content, 'utf8');
console.log('Replaced successfully.');
