const fs = require('fs');

const viDict = {
  'Thiết lập tài khoản và phân quyền nhân viên': { en: 'Account settings and role permissions', ja: 'アカウント設定と権限' },
  'Họ Tên': { en: 'Full Name', ja: '氏名' },
  'Vai Trò (Role)': { en: 'Role', ja: '役割' },
  'Trạng thái': { en: 'Status', ja: 'ステータス' },
  'Hành động': { en: 'Action', ja: 'アクション' },
  'Tháng / Năm': { en: 'Month / Year', ja: '月 / 年' },
  'Mục tiêu Doanh Thu (VNĐ)': { en: 'Revenue Target (VND)', ja: '目標売上（VND）' },
  'Tỷ lệ COGS tối đa (%)': { en: 'Max COGS Ratio (%)', ja: '最大原価率（%）' },
  'Tỷ lệ Lấp đầy bàn (%)': { en: 'Table Occupancy Rate (%)', ja: 'テーブル稼働率（%）' },
  'Giá trị TB/Hóa đơn (VNĐ)': { en: 'Avg Value/Invoice (VND)', ja: '平均客単価（VND）' },
  'Số Khách': { en: 'Guests', ja: '客数' },
  'Tỷ lệ COGS': { en: 'COGS Ratio', ja: '原価率' },
  'Tỷ lệ Lấp Đầy': { en: 'Occupancy Rate', ja: '稼働率' },
  'Giá trị TB/Hóa đơn': { en: 'Avg Value/Invoice', ja: '平均客単価' },
  'Tháng': { en: 'Month', ja: '月' },
  'Giám sát mọi thao tác và thay đổi dữ liệu trong hệ thống': { en: 'Monitor all operations and data changes in the system', ja: 'システム内のすべての操作とデータ変更を監視する' },
  'Thời Gian': { en: 'Time', ja: '時間' },
  'Nhánh': { en: 'Branch', ja: '支店' },
  'Người dùng': { en: 'User', ja: 'ユーザー' },
  'Loại đối tượng': { en: 'Object Type', ja: 'オブジェクトタイプ' },
  'Hiển thị 1-10 trên 150 kết quả': { en: 'Showing 1-10 of 150 results', ja: '150件中1〜10件を表示' },
  'Trống': { en: 'Empty', ja: '空席' }
};

// Also strip out "Eng: " and "Ja: " globally
function fixLocale(file, prefix, targetDictKey) {
  let content = fs.readFileSync(file, 'utf8');
  
  // 1. Strip the prefixes first
  const regex = new RegExp(`['"]${prefix}\\s*(.*?)['"]`, 'g');
  content = content.replace(regex, "'$1'");
  
  // 2. Now apply specific translations by reading vi.ts and mapping keys
  const viContent = fs.readFileSync('src/locales/vi.ts', 'utf8');
  for (const [viText, translations] of Object.entries(viDict)) {
    // Find key in vi.ts
    // e.g. auto_key: "viText"
    const keyMatch = new RegExp(`(auto_[a-zA-Z0-9_]+):\\s*['"]${viText.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}['"]`).exec(viContent);
    if (keyMatch) {
      const key = keyMatch[1];
      const targetTrans = translations[targetDictKey];
      // Replace in content
      const replaceRegex = new RegExp(`(${key}:\\s*)['"][^'"]*['"]`);
      content = content.replace(replaceRegex, `$1'${targetTrans.replace(/'/g, "\\'")}'`);
    }
  }

  fs.writeFileSync(file, content);
}

fixLocale('src/locales/en.ts', 'Eng:', 'en');
fixLocale('src/locales/ja.ts', 'Ja:', 'ja');
console.log('Locales fixed!');
