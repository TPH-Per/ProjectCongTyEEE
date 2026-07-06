const fs = require('fs');

const file = 'src/views/purchasing/ReceiptsManagerView.vue';
let content = fs.readFileSync(file, 'utf8');

// Ensure we extract t from i18nStore
if (!content.includes('const { t } = i18nStore')) {
    content = content.replace(/const i18nStore = useI18nStore\(\)/, "const i18nStore = useI18nStore()\nconst { t } = i18nStore");
}

// Replace $t('...', '...') -> t('...')
// The regex finds $t( or i18nStore.t( with optional whitespace, a quote, the key, a quote, then optionally a comma and a string fallback, and the closing parenthesis
const regex1 = /\$?t\(\s*(['"][^'"]+['"])\s*,\s*['"][^'"]+['"]\s*\)/g;
content = content.replace(regex1, "t($1)");

// Replace $t('...') -> t('...')
const regex2 = /\$t\(\s*(['"][^'"]+['"])\s*\)/g;
content = content.replace(regex2, "t($1)");

// Replace i18nStore.t('...') -> t('...')
const regex3 = /i18nStore\.t\(\s*(['"][^'"]+['"])\s*\)/g;
content = content.replace(regex3, "t($1)");

fs.writeFileSync(file, content);
console.log('Vue file updated');
