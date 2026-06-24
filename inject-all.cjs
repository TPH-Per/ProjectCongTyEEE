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

targets.forEach(relPath => {
  const p = path.join(__dirname, relPath);
  if (!fs.existsSync(p)) return;
  
  let content = fs.readFileSync(p, 'utf8');
  if (content.includes("t('") && !content.includes('useI18n')) {
    if (!content.includes('<script')) {
      content += `\n<script setup lang="ts">\nimport { useI18n } from 'vue-i18n';\nconst { t } = useI18n();\n</script>\n`;
    } else {
      content = content.replace(/<script([^>]*)>/, `<script$1>\nimport { useI18n } from 'vue-i18n';\nconst { t } = useI18n();`);
    }
    fs.writeFileSync(p, content);
    console.log("Injected script in", relPath);
  }
});
