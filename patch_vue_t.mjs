import fs from 'fs';

const files = [
  'src/views/reception/ReceptionDashboardView.vue',
  'src/views/reception/ReceptionCheckoutView.vue',
  'src/views/reception/ReceptionCloseShiftView.vue',
  'src/views/reception/ReceptionOrderView.vue'
];

for (const file of files) {
  let content = fs.readFileSync(file, 'utf-8');
  
  // Replace import
  content = content.replace(/import\s+{\s*useI18n\s*}\s+from\s+['"]vue-i18n['"]/, "import { useLanguageStore } from '@/stores/useLanguageStore'");
  
  // Replace const { t } = useI18n()
  content = content.replace(/const\s+{\s*t\s*}\s*=\s*useI18n\(\)/, "const langStore = useLanguageStore()\n  const t = langStore.t");
  
  // Replace $t( with t(
  content = content.replace(/\$t\(/g, "t(");
  
  fs.writeFileSync(file, content);
  console.log(`Updated ${file}`);
}
