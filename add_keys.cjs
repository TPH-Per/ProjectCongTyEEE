const fs = require('fs');

['vi', 'en', 'ja'].forEach(locale => {
  let content = fs.readFileSync('src/locales/' + locale + '.ts', 'utf8');
  const dThu = locale === 'vi' ? 'Doanh Thu' : locale === 'en' ? 'Revenue' : '売上';
  const cogs = locale === 'vi' ? 'Giá Vốn (COGS)' : locale === 'en' ? 'COGS' : '売上原価 (COGS)';
  const newKeys = `  auto_doanh_thu: '${dThu}',\n  auto_cogs: '${cogs}',\n`;
  content = content.replace(/(export default \{)/, `$1\n${newKeys}`);
  fs.writeFileSync('src/locales/' + locale + '.ts', content);
});
