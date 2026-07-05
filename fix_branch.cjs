const fs = require('fs');

function replaceInFile(filename, searchStr, replaceStr) {
    let content = fs.readFileSync(filename, 'utf8');
    content = content.replace(searchStr, replaceStr);
    fs.writeFileSync(filename, content);
}

replaceInFile('src/locales/en.ts', "'branch.phone': 'Số điện thoại'", "'branch.phone': 'Phone Number'");
replaceInFile('src/locales/en.ts', "'branch.address': 'Địa chỉ'", "'branch.address': 'Address'");
replaceInFile('src/locales/en.ts', "'branch.name': 'Tên chi nhánh'", "'branch.name': 'Branch Name'");

replaceInFile('src/locales/ja.ts', "'branch.phone': 'Số điện thoại'", "'branch.phone': '電話番号'");
replaceInFile('src/locales/ja.ts', "'branch.address': 'Địa chỉ'", "'branch.address': '住所'");
replaceInFile('src/locales/ja.ts', "'branch.name': 'Tên chi nhánh'", "'branch.name': '支店名'");

console.log('Fixed branch translations in en.ts and ja.ts');
