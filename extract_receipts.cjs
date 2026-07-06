const fs = require('fs');
const content = fs.readFileSync('src/views/purchasing/ReceiptsManagerView.vue', 'utf8');
const regex = /\$?t\(\s*['"]([^'"]+)['"]\s*,\s*['"]([^'"]+)['"]/g;
let match;
const dict = {};
while ((match = regex.exec(content)) !== null) {
  dict[match[1]] = match[2];
}
// check single quotes with double quotes inside
const regex2 = /\$?t\(\s*['"]([^'"]+)['"]\s*,\s*`([^`]+)`/g;
while ((match = regex2.exec(content)) !== null) {
  dict[match[1]] = match[2];
}
// i18nStore.t('purchasing.receipts.alert.selectSupplier') without fallback
const regex3 = /i18nStore\.t\(\s*['"]([^'"]+)['"]\s*\)/g;
while ((match = regex3.exec(content)) !== null) {
  if (!dict[match[1]]) {
      dict[match[1]] = match[1]; // Just set the key as value for now
  }
}

fs.writeFileSync('receipts_dict.json', JSON.stringify(dict, null, 2));
console.log('Found ' + Object.keys(dict).length + ' keys');
