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
      if (name.endsWith('.vue') || name.endsWith('.ts')) {
        files_.push(name);
      }
    }
  }
  return files_;
}

const allFiles = getFiles('src');

for (const file of allFiles) {
  let content = fs.readFileSync(file, 'utf8');
  let changed = false;

  if (content.includes('alert(')) {
    content = content.replace(/alert\((.*)\)/g, (match, p1) => {
      let isError = p1.toLowerCase().includes('lỗi') || p1.toLowerCase().includes('error') || p1.toLowerCase().includes('failed');
      let type = isError ? 'error' : 'info';
      let title = isError ? 'Lỗi' : 'Thông báo';
      if (p1.toLowerCase().includes('thành công') || p1.toLowerCase().includes('success')) {
        type = 'success';
        title = 'Thành công';
      }
      return `Swal.fire('${title}', ${p1}, '${type}')`;
    });
    
    if (!content.includes('import Swal from')) {
      content = content.replace(/<script setup lang="ts">\s*/g, '<script setup lang="ts">\nimport Swal from \'sweetalert2\';\n');
      if (!content.includes('import Swal')) {
        content = content.replace(/<script setup>\s*/g, '<script setup>\nimport Swal from \'sweetalert2\';\n');
      }
    }
    changed = true;
  }
  
  if (content.includes('confirm(')) {
    content = content.replace(/confirm\((.*)\)/g, `await Swal.fire({\n      title: 'Xác nhận',\n      text: $1,\n      icon: 'warning',\n      showCancelButton: true,\n      confirmButtonText: 'Đồng ý',\n      cancelButtonText: 'Hủy'\n    }).then((result) => result.isConfirmed)`);
    if (!content.includes('import Swal from')) {
      content = content.replace(/<script setup lang="ts">\s*/g, '<script setup lang="ts">\nimport Swal from \'sweetalert2\';\n');
    }
    changed = true;
  }

  if (changed) {
    fs.writeFileSync(file, content);
    console.log('Updated', file);
  }
}
