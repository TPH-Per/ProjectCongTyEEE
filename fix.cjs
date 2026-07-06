
const fs = require('fs');
const path = require('path');
const layoutsDir = path.join('src', 'layouts');
const files = fs.readdirSync(layoutsDir);

files.forEach(file => {
  if (file.endsWith('Layout.vue')) {
    const filePath = path.join(layoutsDir, file);
    let code = fs.readFileSync(filePath, 'utf8');
    
    // add z-40 to header if it has sticky top-0
    code = code.replace(/(<header[^>]*\bsticky\s+top-0\b)(?!\s+z-)/g, '\ z-40');
    
    // Add z-40 to any header that has border-b but no z- index
    code = code.replace(/(<header class=\x22[^\x22]*border-b[^\x22]*)(?!\s+z-)\x22/g, '\ z-40\x22');

    fs.writeFileSync(filePath, code);
  }
});
console.log('Added z-40 to layout headers');

