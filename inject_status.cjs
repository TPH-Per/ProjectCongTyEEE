const fs = require('fs');

const missingEn = `
  auto_khong_tim_thay_ban: 'No tables found in this zone.',
  auto_phan_khu: 'Zone',
  auto_trong: 'Available',
  auto_dat_truoc: 'Reserved',
  auto_da_den: 'Arrived',
  auto_phuc_vu: 'Serving',
  auto_bao_tri: 'Maintenance',
  auto_cho_xep: 'Waiting',
  auto_dang_dung: 'Seated',
  auto_da_xong: 'Completed',
  auto_da_huy: 'Cancelled',
`;

const missingJa = `
  auto_khong_tim_thay_ban: 'このゾーンにはテーブルがありません。',
  auto_phan_khu: 'ゾーン',
  auto_trong: '空席',
  auto_dat_truoc: '予約済み',
  auto_da_den: '到着済み',
  auto_phuc_vu: '提供中',
  auto_bao_tri: 'メンテナンス',
  auto_cho_xep: '待機中',
  auto_dang_dung: '着席',
  auto_da_xong: '完了',
  auto_da_huy: 'キャンセル',
`;

const missingVi = `
  auto_khong_tim_thay_ban: 'Không tìm thấy bàn nào thuộc phân khu này.',
  auto_phan_khu: 'Phân khu',
  auto_trong: 'Trống',
  auto_dat_truoc: 'Đặt trước',
  auto_da_den: 'Đã đến',
  auto_phuc_vu: 'Phục vụ',
  auto_bao_tri: 'Bảo trì',
  auto_cho_xep: 'Chờ xếp',
  auto_dang_dung: 'Đang dùng',
  auto_da_xong: 'Đã xong',
  auto_da_huy: 'Đã hủy',
`;

function inject(file, str) {
  let content = fs.readFileSync(file, 'utf8');
  content = content.replace('export default {', 'export default {\n' + str);
  fs.writeFileSync(file, content, 'utf8');
}

inject('src/locales/en.ts', missingEn);
inject('src/locales/ja.ts', missingJa);
inject('src/locales/vi.ts', missingVi);

console.log('Status locales updated successfully.');
