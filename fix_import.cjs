const fs = require('fs');
const layouts = [
  'AdminLayout.vue',
  'DashboardLayout.vue',
  'KitchenLayout.vue',
  'ManagerLayout.vue',
  'ReceptionLayout.vue',
  'StaffLayout.vue',
  'SuperadminLayout.vue'
];
layouts.forEach(file => {
  let p = 'src/layouts/' + file;
  if (!fs.existsSync(p)) return;
  let c = fs.readFileSync(p, 'utf8');
  if (c.includes('<LanguageSwitcher') && !c.includes('import LanguageSwitcher')) {
    c = c.replace(/<script setup lang=\"ts\">/, '<script setup lang=\"ts\">\nimport LanguageSwitcher from \'@/components/LanguageSwitcher.vue\'');
    fs.writeFileSync(p, c);
    console.log('Fixed', file);
  }
});
