const fs = require('fs');
const path = require('path');

const DIRS = [
    path.join(__dirname, 'src', 'views'),
    path.join(__dirname, 'src', 'layouts'),
    path.join(__dirname, 'src', 'components')
];

function getVueFiles(dir) {
    let results = [];
    const list = fs.readdirSync(dir);
    list.forEach(file => {
        file = path.join(dir, file);
        const stat = fs.statSync(file);
        if (stat && stat.isDirectory()) {
            results = results.concat(getVueFiles(file));
        } else if (file.endsWith('.vue')) {
            results.push(file);
        }
    });
    return results;
}

const vueFiles = [];
DIRS.forEach(dir => {
    if (fs.existsSync(dir)) {
        vueFiles.push(...getVueFiles(dir));
    }
});

function toSnakeCase(str) {
    return str.normalize("NFD").replace(/[\u0300-\u036f]/g, "")
              .replace(/đ/g, "d").replace(/Đ/g, "D")
              .replace(/[^a-zA-Z0-9]/g, '_')
              .toLowerCase()
              .replace(/_+/g, '_')
              .replace(/^_|_$/g, '');
}

function hasVietnamese(str) {
    const vietnameseRegex = /[àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ]/i;
    return vietnameseRegex.test(str);
}

const extracted = {};
let totalExtracted = 0;

vueFiles.forEach(file => {
    let content = fs.readFileSync(file, 'utf8');
    let modified = false;

    // Attributes to check: placeholder, title, label, aria-label
    const attrRegex = /\b(placeholder|title|label|aria-label)="([^"]+)"/g;
    
    content = content.replace(attrRegex, (match, attrName, attrValue) => {
        // Skip if it's already translated or doesn't have Vietnamese
        if (!hasVietnamese(attrValue) || attrValue.includes('$t(')) return match;
        
        // Skip if it looks like a variable binding inside quotes (though usually that's without quotes if it's dynamic)
        if (attrValue.includes('{{') || attrValue.includes('}}')) return match;

        let key = 'auto_' + toSnakeCase(attrValue).substring(0, 30);
        extracted[key] = attrValue;
        totalExtracted++;
        modified = true;

        // Change placeholder="Nhập tên" to :placeholder="$t('auto_nhap_ten', 'Nhập tên')"
        return `:${attrName}="$t('${key}', '${attrValue}')"`;
    });

    if (modified) {
        fs.writeFileSync(file, content, 'utf8');
    }
});

console.log(`Extracted ${totalExtracted} new attributes.`);
fs.writeFileSync('extracted_attrs.json', JSON.stringify(extracted, null, 2));

// Update vi.ts
const viPath = path.join(__dirname, 'src', 'locales', 'vi.ts');
let viContent = fs.readFileSync(viPath, 'utf8');
const viEntries = Object.entries(extracted).map(([key, value]) => `  ${key}: '${value.replace(/'/g, "\\'")}',`);
if (viEntries.length > 0) {
    viContent = viContent.replace(/}\s*$/, viEntries.join('\n') + '\n}\n');
    fs.writeFileSync(viPath, viContent, 'utf8');
}
