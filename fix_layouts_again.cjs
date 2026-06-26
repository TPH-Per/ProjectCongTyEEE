const fs = require('fs');

const layoutDict = {
  'Bảng điều khiển': { key: 'auto_bang_dieu_khien', en: 'Dashboard', ja: 'ダッシュボード' },
  'Tổng Kết Ca': { key: 'auto_tong_ket_ca', en: 'Shift Summary', ja: 'シフトサマリー' },
  'Sơ đồ bàn & Đặt chỗ': { key: 'auto_so_do_ban_dat_cho', en: 'Floor Plan & Reservations', ja: 'フロアプランと予約' },
  'Chọn món & Gọi đồ': { key: 'auto_chon_mon_goi_do', en: 'Order & Serving', ja: '注文と提供' },
  'Thanh toán hóa đơn': { key: 'auto_thanh_toan_hoa_don', en: 'Payment', ja: '支払い' },
  'Tổng quan': { key: 'auto_tong_quan', en: 'Overview', ja: '概要' },
  'Quản lý chi nhánh': { key: 'auto_quan_ly_chi_nhanh', en: 'Branch Management', ja: '支店管理' },
  'Tích hợp': { key: 'auto_tich_hop', en: 'Integration', ja: '統合' },
  'Cài đặt hệ thống': { key: 'auto_cai_dat_he_thong', en: 'System Settings', ja: 'システム設定' },
  'Quản lý': { key: 'auto_quan_ly', en: 'Management', ja: '管理' }
};

function fixLayouts() {
  const layoutsDir = 'src/layouts';
  const files = fs.readdirSync(layoutsDir).filter(f => f.endsWith('.vue'));

  for (const file of files) {
    const filePath = `${layoutsDir}/${file}`;
    let content = fs.readFileSync(filePath, 'utf8');
    
    // Add t to script if missing
    if (!content.includes('useI18n') && content.includes('<script setup')) {
      content = content.replace(/<script setup[^>]*>/, "$&\nimport { useI18n } from 'vue-i18n'\nconst { t } = useI18n()");
    }
    
    let modified = false;
    for (const [vnText, trans] of Object.entries(layoutDict)) {
      const regex = new RegExp(vnText, 'g');
      if (regex.test(content)) {
        content = content.replace(regex, `{{ t('${trans.key}') }}`);
        modified = true;
      }
    }
    
    if (modified) {
      fs.writeFileSync(filePath, content);
      console.log(`Updated ${file}`);
    }
  }
}

fixLayouts();

function appendToLocales() {
  for (const locale of ['vi', 'en', 'ja']) {
    let content = fs.readFileSync(`src/locales/${locale}.ts`, 'utf8');
    let injectStr = '';
    for (const [vnText, trans] of Object.entries(layoutDict)) {
      const text = locale === 'vi' ? vnText : trans[locale];
      injectStr += `  ${trans.key}: '${text.replace(/'/g, "\\'")}',\n`;
    }
    content = content.replace(/}\s*$/, `${injectStr}}`);
    fs.writeFileSync(`src/locales/${locale}.ts`, content);
  }
}

appendToLocales();
console.log('Layout translations added to locales!');
