const fs = require('fs');
const path = require('path');

const targets = [
  'src/views/admin/AdminAccountsView.vue', 'src/views/admin/AdminAuditView.vue', 'src/views/admin/AdminDashboardView.vue',
  'src/views/admin/AdminFloorsView.vue', 'src/views/admin/AdminKPIView.vue', 'src/views/admin/AdminMenusView.vue',
  'src/views/manager/ManagerCOGSView.vue', 'src/views/manager/ManagerCRMView.vue', 'src/views/manager/ManagerDashboardView.vue',
  'src/views/manager/ManagerInventoryView.vue', 'src/views/manager/ManagerMarketingView.vue', 'src/views/manager/ManagerRevenueView.vue',
  'src/views/staff/StaffActiveTablesView.vue', 'src/views/staff/StaffFloorPlanView.vue', 'src/views/staff/StaffInDiningCRMView.vue',
  'src/views/staff/StaffOpenTableView.vue', 'src/views/reception/ReceptionCheckoutView.vue', 'src/views/reception/ReceptionCloseShiftView.vue',
  'src/views/reception/ReceptionDashboardView.vue', 'src/views/kitchen/KitchenKDSView.vue', 'src/views/superadmin/SuperadminBrandsView.vue',
  'src/views/superadmin/SuperadminDashboardView.vue', 'src/views/superadmin/SuperadminIntegrationsView.vue', 'src/views/tablet/TabletCheckoutView.vue',
  'src/views/tablet/TabletIdleView.vue', 'src/views/tablet/TabletLanguageView.vue', 'src/views/tablet/TabletOrderView.vue',
  'src/views/LoginView.vue', 'src/views/FloorPlanView.vue', 'src/views/ListView.vue', 'src/views/TimelineView.vue'
];

const dict = {
  "Quản Lý Tài Khoản": { en: "Account Management", ja: "アカウント管理" },
  "Đang tải...": { en: "Loading...", ja: "読み込み中..." },
  "Tìm tên...": { en: "Search name...", ja: "名前を検索..." },
  "Thêm món": { en: "Add item", ja: "アイテムを追加" },
  "Thanh toán": { en: "Checkout", ja: "チェックアウト" },
  "Lưu": { en: "Save", ja: "保存" },
  "Hủy": { en: "Cancel", ja: "キャンセル" },
  "Xóa": { en: "Delete", ja: "削除" },
  "Xác nhận": { en: "Confirm", ja: "確認" },
  "Chi tiết": { en: "Details", ja: "詳細" },
  "Thành công": { en: "Success", ja: "成功" },
  "Thất bại": { en: "Failed", ja: "失敗" },
  "Danh sách": { en: "List", ja: "リスト" },
  "Tất cả": { en: "All", ja: "すべて" },
  "Báo cáo": { en: "Reports", ja: "レポート" },
  "Tổng quan": { en: "Overview", ja: "概要" },
  "Sơ đồ bàn": { en: "Floor Plan", ja: "フロアプラン" },
  "Mở bàn": { en: "Open Table", ja: "テーブルを開く" },
  "Đóng ca": { en: "Close Shift", ja: "シフト終了" },
  "Đăng nhập": { en: "Login", ja: "ログイン" },
  "Tên đăng nhập": { en: "Username", ja: "ユーザー名" },
  "Mật khẩu": { en: "Password", ja: "パスワード" },
  "Bếp": { en: "Kitchen", ja: "キッチン" }
};

let globalTranslations = {};

targets.forEach(relPath => {
  const p = path.join(__dirname, relPath);
  if (!fs.existsSync(p)) return;
  
  let content = fs.readFileSync(p, 'utf8');
  let hasChanges = false;
  
  // match things that look like Viet text. Make sure we don't grab newlines or large HTML chunks
  const regex = />([^<\{\}\n\r]+)</g;
  
  content = content.replace(regex, (match, text) => {
    const trimmed = text.trim();
    if (!trimmed || trimmed.length < 3) return match;
    
    // Ignore pure English technical terms, symbols, numbers
    if (/^[A-Za-z0-9\s\.\-_:]+$/.test(trimmed) && !trimmed.includes(' ') && trimmed.length < 6) return match;
    if (!/[À-ỹ]/.test(trimmed)) {
       // if no vietnamese characters, skip
       // actually, some caps might just be English. Let's strictly require at least one Viet char or common words
       const hasViet = /[áàảãạâấầẩẫậăắằẳẵặéèẻẽẹêếềểễệíìỉĩịóòỏõọôốồổỗộơớờởỡợúùủũụưứừửữựýỳỷỹỵđÁÀẢÃẠÂẤẦẨẪẬĂẮẰẲẴẶÉÈẺẼẸÊẾỀỂỄỆÍÌỈĨỊÓÒỎÕỌÔỐỒỔỖỘƠỚỜỞỠỢÚÙỦŨỤƯỨỪỬỮỰÝỲỶỸỴĐ]/.test(trimmed);
       if (!hasViet) return match;
    }
    
    const key = 'auto_' + trimmed.toLowerCase().replace(/[^a-z0-9]/g, '_').substring(0, 30);
    globalTranslations[key] = trimmed;
    hasChanges = true;
    return match.replace(trimmed, `{{ t('${key}') }}`);
  });
  
  if (hasChanges && !content.includes('useI18n')) {
    content = content.replace(/<script setup lang="ts">/g, `<script setup lang="ts">\nimport { useI18n } from 'vue-i18n'\nconst { t } = useI18n()`);
  }
  
  if (hasChanges) {
    fs.writeFileSync(p, content);
  }
});

function translate(viText, lang) {
  for (const [vi, trans] of Object.entries(dict)) {
    if (viText.includes(vi) || vi.includes(viText)) {
      return trans[lang];
    }
  }
  if (lang === 'en') return "Eng: " + viText;
  if (lang === 'ja') return "Ja: " + viText;
  return viText;
}

const localesDir = path.join(__dirname, 'src', 'locales');
['vi.ts', 'en.ts', 'ja.ts'].forEach(file => {
  const p = path.join(localesDir, file);
  if (!fs.existsSync(p)) return;
  let loc = fs.readFileSync(p, 'utf8');
  
  let injection = '';
  for (const [k, v] of Object.entries(globalTranslations)) {
    let val = v;
    if (file === 'en.ts') val = translate(v, 'en');
    if (file === 'ja.ts') val = translate(v, 'ja');
    // Using JSON.stringify ensures double quotes, newlines, etc are safely escaped
    injection += `  ${k}: ${JSON.stringify(val)},\n`;
  }
  
  loc = loc.replace(/export default\s*\{/, `export default {\n${injection}`);
  fs.writeFileSync(p, loc);
});

console.log("Extracted keys:", Object.keys(globalTranslations).length);
