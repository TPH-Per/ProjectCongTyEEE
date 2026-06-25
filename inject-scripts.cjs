const fs = require('fs');
const path = require('path');

const targets = [
  'src/views/admin/AdminMenusView.vue',
  'src/views/staff/StaffInDiningCRMView.vue',
  'src/views/tablet/TabletIdleView.vue',
  'src/views/tablet/TabletLanguageView.vue'
];

targets.forEach(relPath => {
  const p = path.join(__dirname, relPath);
  if (!fs.existsSync(p)) return;
  
  let content = fs.readFileSync(p, 'utf8');
  if (content.includes("t('") && !content.includes('useI18n')) {
    if (!content.includes('<script')) {
      content += `\n<script setup lang="ts">\nimport { useI18n } from 'vue-i18n';\nconst { t } = useI18n();\n</script>\n`;
    } else {
      // Find the existing script tag
      content = content.replace(/<script([^>]*)>/, `<script$1>\nimport { useI18n } from 'vue-i18n';\nconst { t } = useI18n();`);
    }
    fs.writeFileSync(p, content);
    console.log("Injected script in", relPath);
  }
});
