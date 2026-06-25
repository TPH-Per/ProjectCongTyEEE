const fs = require('fs');
let code = fs.readFileSync('src/views/admin/AdminFloorsView.vue', 'utf8');

// Replace alerts
code = code.replace(/alert\((.*)\)/g, (match, p1) => {
  let isError = p1.toLowerCase().includes('lỗi') || p1.toLowerCase().includes('error') || p1.toLowerCase().includes('failed');
  let type = isError ? 'error' : 'info';
  let title = isError ? 'Lỗi' : 'Thông báo';
  return `Swal.fire('${title}', ${p1}, '${type}')`;
});

// Add Swal import
if (!code.includes('import Swal from')) {
  code = code.replace(/<script setup lang="ts">\n/g, '<script setup lang="ts">\nimport Swal from \'sweetalert2\';\n');
}

// Fix confirm
code = code.replace(
  "if (confirm('Bạn có chắc chắn muốn hủy lượt đặt bàn này không?')) {",
  "if (await Swal.fire({ title: 'Xác nhận', text: 'Bạn có chắc chắn muốn hủy lượt đặt bàn này không?', icon: 'warning', showCancelButton: true, confirmButtonText: 'Đồng ý', cancelButtonText: 'Hủy' }).then(r => r.isConfirmed)) {"
);
code = code.replace("function cancelBooking(id: string) {", "async function cancelBooking(id: string) {");

fs.writeFileSync('src/views/admin/AdminFloorsView.vue', code);
console.log('Fixed AdminFloorsView.vue');
