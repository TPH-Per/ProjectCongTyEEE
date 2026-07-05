const fs = require('fs');
const transData = JSON.parse(fs.readFileSync('translations_data.json', 'utf8'));

// Update store
const storePath = 'src/stores/useLanguageStore.ts';
let storeContent = fs.readFileSync(storePath, 'utf8');

const keys = { vi: [], en: [], ja: [] };
for (const [viText, data] of Object.entries(transData)) {
    keys.vi.push(`    'reception.${data.key}': ${JSON.stringify(viText)}`);
    keys.en.push(`    'reception.${data.key}': ${JSON.stringify(data.en)}`);
    keys.ja.push(`    'reception.${data.key}': ${JSON.stringify(data.ja)}`);
}

['vi', 'en', 'ja'].forEach(lang => {
    const regex = new RegExp(`(${lang}:\\s*\\{[\\s\\S]*?)(\\n\\s*\\})`);
    storeContent = storeContent.replace(regex, `$1,\n${keys[lang].join(',\n')}$2`);
});

fs.writeFileSync(storePath, storeContent);

// Process Vue Files
const files = [
  'src/views/reception/ReceptionOrderView.vue',
  'src/views/reception/ReportsView.vue',
  'src/views/reception/ReceptionCloseShiftView.vue',
  'src/views/reception/ReceptionDashboardView.vue'
];

files.forEach(f => {
  if (!fs.existsSync(f)) return;
  let content = fs.readFileSync(f, 'utf8');
  
  if (!content.includes('useLanguageStore')) {
     content = content.replace(/<script setup lang="ts">/, `<script setup lang="ts">\nimport { useLanguageStore } from '@/stores/useLanguageStore';\nconst languageStore = useLanguageStore();\nconst { t } = languageStore;\n`);
  } else if (!content.includes('const { t } =')) {
     content = content.replace(/const languageStore = useLanguageStore\(\);/, `const languageStore = useLanguageStore();\nconst { t } = languageStore;`);
  }

  // Handle template tags
  for (const [viText, data] of Object.entries(transData)) {
      const escaped = viText.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
      
      const nodeRegex = new RegExp(`>\\s*${escaped}\\s*<`, 'g');
      content = content.replace(nodeRegex, `>{{ t('reception.${data.key}') }}<`);

      const attrRegex1 = new RegExp(`placeholder="${escaped}"`, 'g');
      content = content.replace(attrRegex1, `:placeholder="t('reception.${data.key}')"`);

      const attrRegex2 = new RegExp(`label="${escaped}"`, 'g');
      content = content.replace(attrRegex2, `:label="t('reception.${data.key}')"`);
      
      const attrRegex3 = new RegExp(`title="${escaped}"`, 'g');
      content = content.replace(attrRegex3, `:title="t('reception.${data.key}')"`);
  }
  
  fs.writeFileSync(f, content);
});
console.log('Update Complete');
