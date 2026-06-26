const fs = require('fs');

const layoutsDir = 'src/layouts';
const files = fs.readdirSync(layoutsDir).filter(f => f.endsWith('.vue'));

for (const file of files) {
  const filePath = `${layoutsDir}/${file}`;
  let content = fs.readFileSync(filePath, 'utf8');
  
  // Fix the invalid TS injected by the previous script:
  // '{ name: '{{ t('auto_tong_quan') }}', ...' -> '{ name: t('auto_tong_quan'), ...'
  content = content.replace(/'\{\{\s*(t\('[^']+'\))\s*\}\}'/g, "$1");
  content = content.replace(/"\{\{\s*(t\('[^']+'\))\s*\}\}"/g, "$1");
  
  fs.writeFileSync(filePath, content);
}
