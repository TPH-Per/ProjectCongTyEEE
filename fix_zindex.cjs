const fs = require('fs');
const path = require('path');
const layoutsDir = path.join('src', 'layouts');
const files = fs.readdirSync(layoutsDir);

files.forEach(file => {
  if (file.endsWith('Layout.vue') && file !== 'ManagerLayout.vue' && file !== 'SuperadminLayout.vue') {
    const filePath = path.join(layoutsDir, file);
    let code = fs.readFileSync(filePath, 'utf8');
    
    // add z-40 to header if it has sticky top-0
    code = code.replace(/(<header[^>]*\bsticky\s+top-0\b)(?!\s+z-)/g, '$1 z-40');
    
    // Add z-40 to any header that has border-b but no z- index
    code = code.replace(/(<header class="[^"]*border-b[^"]*)(?!\s+z-)(")/g, '$1 z-40$2');

    fs.writeFileSync(filePath, code);
  }
});
console.log('Fixed other layout headers');
