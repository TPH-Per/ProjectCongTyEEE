const fs = require('fs');
const path = require('path');
const p = path.join('src', 'locales', 'vi.ts');
let c = fs.readFileSync(p, 'utf8');

const newKeys = {
  'auto_placeholder_fix': 'Nhập...',
  'auto_ban_dang_hd': 'bàn đang hoạt động',
  'auto_khach': 'Khách:',
  'auto_nguoi': 'người',
  'auto_dang_phuc_vu': 'Đang phục vụ',
  'auto_suc_chua': 'Sức chứa:',
  'auto_dang_luu': 'Đang lưu...',
  'auto_cap_nhat_tt': 'Cập nhật Thông tin',
  'auto_mo_ban': 'Mở bàn:',
  'auto_dang_xu_ly': 'Đang xử lý...',
  'auto_mo_ban_kich_hoat': 'Mở Bàn & Kích Hoạt Tablet',
  'auto_hoat_dong': 'Hoạt động',
  'auto_tam_ngung': 'Tạm ngưng',
  'auto_ban': 'bàn',
  'auto_cong_suat': 'Công suất',
  'auto_dang_gui': 'Đang gửi...',
  'auto_gui_bep': 'Gửi Bếp'
};

let toAppend = '';
for (const [k, v] of Object.entries(newKeys)) {
  if (!c.includes('\'' + k + '\'')) {
    toAppend += `  '${k}': '${v}',\n`;
  }
}

if (toAppend) {
  // replace the last } with the new keys + }
  const lastBraceIndex = c.lastIndexOf('}');
  c = c.substring(0, lastBraceIndex) + toAppend + '}\n';
  fs.writeFileSync(p, c);
  console.log('Added new keys to vi.ts');
} else {
  console.log('No new keys to add.');
}
