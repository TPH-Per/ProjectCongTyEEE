const fs = require('fs');

const appendKeys = (file, keys) => {
  let content = fs.readFileSync(file, 'utf8');
  for (const [key, val] of Object.entries(keys)) {
    if (!content.includes(key + ':')) {
      content = content.replace(/(export default \{[\s\S]*?)(\n\})/, `$1,\n  ${key}: '${val}'$2`);
    }
  }
  fs.writeFileSync(file, content, 'utf8');
};

appendKeys('src/locales/en.ts', {
  auto_trong_nho: 'available',
  auto_thi_t_l_p_tr_ng: 'Set Available',
  auto_luu_thiet_lap: 'Save Configuration',
  auto_dang_luu: 'Saving...',
  auto_khong_tim_thay_ban: 'No tables found in this zone.'
});

appendKeys('src/locales/ja.ts', {
  auto_trong_nho: '空席',
  auto_thi_t_l_p_tr_ng: '空席に設定',
  auto_luu_thiet_lap: '設定を保存',
  auto_dang_luu: '保存中...',
  auto_khong_tim_thay_ban: 'このゾーンにはテーブルがありません。'
});

appendKeys('src/locales/vi.ts', {
  auto_trong_nho: 'trống',
  auto_thi_t_l_p_tr_ng: 'Thiết lập Trống',
  auto_luu_thiet_lap: 'Lưu Thiết Lập',
  auto_dang_luu: 'Đang lưu...',
  auto_khong_tim_thay_ban: 'Không tìm thấy bàn nào thuộc phân khu này.'
});

console.log('Translations updated.');
