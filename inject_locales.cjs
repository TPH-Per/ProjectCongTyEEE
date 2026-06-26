const fs = require('fs');

const missingEn = `
  auto_ghe: 'seats',
  auto_khach: 'guests',
  auto_ghe_ngoi: 'seats',
  auto_cho: 'spots',
  auto_cho_ngoi: 'Seats',
  auto_chi_tiet_ban: 'Table Details',
`;

const missingJa = `
  auto_ghe: '席',
  auto_khach: '名',
  auto_ghe_ngoi: '席',
  auto_cho: '席',
  auto_cho_ngoi: '席',
  auto_chi_tiet_ban: 'テーブル詳細',
`;

const missingVi = `
  auto_ghe: 'ghế',
  auto_khach: 'khách',
  auto_ghe_ngoi: 'ghế ngồi',
  auto_cho: 'chỗ',
  auto_cho_ngoi: 'Chỗ ngồi',
  auto_chi_tiet_ban: 'Chi Tiết Bàn',
`;

function inject(file, str) {
  let content = fs.readFileSync(file, 'utf8');
  content = content.replace('export default {', 'export default {\n' + str);
  fs.writeFileSync(file, content, 'utf8');
}

inject('src/locales/en.ts', missingEn);
inject('src/locales/ja.ts', missingJa);
inject('src/locales/vi.ts', missingVi);

console.log('Locales updated successfully.');
