const fs = require('fs');
const files = ['src/locales/vi.ts', 'src/locales/en.ts', 'src/locales/ja.ts'];
files.forEach(f => {
    let content = fs.readFileSync(f, 'utf8');
    
    // Add missing branch translations if not exist
    if (!content.includes('branch.name')) {
        content = content.replace(/'branch\.title':.*,/, 
            "$&" + "\n  'branch.name': 'Tên chi nhánh',"
        );
    }
    if (!content.includes('branch.address')) {
        content = content.replace(/'branch\.title':.*,/, 
            "$&" + "\n  'branch.address': 'Địa chỉ',"
        );
    }
    if (!content.includes('branch.phone')) {
        content = content.replace(/'branch\.title':.*,/, 
            "$&" + "\n  'branch.phone': 'Số điện thoại',"
        );
    }
    
    fs.writeFileSync(f, content);
});
console.log('Translations updated.');
