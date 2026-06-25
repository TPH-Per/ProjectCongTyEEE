const fs = require('fs');
const path = require('path');

function getFiles(dir, files_) {
  files_ = files_ || [];
  const files = fs.readdirSync(dir);
  for (const i in files) {
    const name = dir + '/' + files[i];
    if (fs.statSync(name).isDirectory()) {
      getFiles(name, files_);
    } else {
      if (name.endsWith('.vue')) files_.push(name);
    }
  }
  return files_;
}

const allFiles = getFiles('src/views');
const viPath = 'src/locales/vi.ts';
let viContent = fs.readFileSync(viPath, 'utf8');

const viRegex = />([^<\{\}]*[àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴÈÉẸẺẼÊỀẾỆỂỄÌÍỊỈĨÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠÙÚỤỦŨƯỪỨỰỬỮỲÝỴỶỸĐ]+[^<\{\}]*)</g;
const attrRegex = /\b(placeholder|title|label|alt)="([^"]*[àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴÈÉẸẺẼÊỀẾỆỂỄÌÍỊỈĨÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠÙÚỤỦŨƯỪỨỰỬỮỲÝỴỶỸĐ]+[^"]*)"/g;

function slugify(text) {
  return 'auto_' + text.toLowerCase().replace(/[^a-z0-9]/g, '_').substring(0, 30).replace(/_+/g, '_').replace(/^_|_$/g, '');
}

const newKeys = {};

for (const file of allFiles) {
  let content = fs.readFileSync(file, 'utf8');
  let changed = false;

  content = content.replace(viRegex, (match, text) => {
    let cleanText = text.trim();
    if (cleanText.length === 0) return match;
    let key = slugify(cleanText);
    newKeys[key] = cleanText;
    
    let leadingSpace = text.match(/^\s*/)[0];
    let trailingSpace = text.match(/\s*$/)[0];
    return `>${leadingSpace}{{ t('${key}', '${cleanText.replace(/'/g, "\\'")}') }}${trailingSpace}<`;
  });

  content = content.replace(attrRegex, (match, attrName, text) => {
    let cleanText = text.trim();
    if (cleanText.length === 0) return match;
    let key = slugify(cleanText);
    newKeys[key] = cleanText;
    return `:${attrName}="t('${key}', '${cleanText.replace(/'/g, "\\'")}')"`;
  });

  if (content !== fs.readFileSync(file, 'utf8')) {
    fs.writeFileSync(file, content, 'utf8');
    console.log(`Updated i18n in ${file}`);
  }
}

// Ensure viContent has the new keys
let viEntries = "";
for (const [key, val] of Object.entries(newKeys)) {
  if (!viContent.includes(`${key}:`)) {
    viEntries += `  ${key}: ${JSON.stringify(val)},\n`;
  }
}

if (viEntries) {
  viContent = viContent.replace(/export default \{/, `export default {\n${viEntries}`);
  fs.writeFileSync(viPath, viContent, 'utf8');
  console.log(`Added ${Object.keys(newKeys).length} new keys to vi.ts`);
}
