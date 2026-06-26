const fs = require('fs');
let content = fs.readFileSync('src/views/admin/AdminFloorsView.vue', 'utf8');

// Phân khu replacements
content = content.replace(
  /"Không tìm thấy bàn nào thuộc phân khu này\.",/g,
  `t('auto_khong_tim_thay_ban', 'Không tìm thấy bàn nào thuộc phân khu này.'),`
);

content = content.replace(
  /Phân khu: \{\{ selectedTableForModal\.areaName \}\}/g,
  `{{ t('auto_phan_khu', 'Phân khu') }}: {{ selectedTableForModal.areaName }}`
);

content = content.replace(
  /function translateTableStatus\(status: string\) \{\s*switch \(status\) \{\s*case 'Available': return 'Trống'\s*case 'Reserved': return 'Đặt trước'\s*case 'Arrived': return 'Đã đến'\s*case 'Serving': return 'Phục vụ'\s*case 'Maintenance': return 'Bảo trì'\s*default: return status\s*\}\s*\}/,
  `function translateTableStatus(status: string) {
  switch (status) {
    case 'Available': return t('auto_trong', 'Trống')
    case 'Reserved': return t('auto_dat_truoc', 'Đặt trước')
    case 'Arrived': return t('auto_da_den', 'Đã đến')
    case 'Serving': return t('auto_phuc_vu', 'Phục vụ')
    case 'Maintenance': return t('auto_bao_tri', 'Bảo trì')
    default: return status
  }
}`
);

content = content.replace(
  /function translateReservationStatus\(status: 'Waiting' \| 'Arrived' \| 'Seated' \| 'Completed' \| 'Cancelled'\) \{\s*switch \(status\) \{\s*case 'Waiting': return 'Chờ xếp'\s*case 'Arrived': return 'Đã đến'\s*case 'Seated': return 'Đã ngồi'\s*case 'Completed': return 'Hoàn tất'\s*case 'Cancelled': return 'Đã hủy'\s*default: return status\s*\}\s*\}/,
  `function translateReservationStatus(status: 'Waiting' | 'Arrived' | 'Seated' | 'Completed' | 'Cancelled') {
  switch (status) {
    case 'Waiting': return t('auto_cho_xep', 'Chờ xếp')
    case 'Arrived': return t('auto_da_den', 'Đã đến')
    case 'Seated': return t('auto_dang_dung', 'Đang dùng')
    case 'Completed': return t('auto_da_xong', 'Đã xong')
    case 'Cancelled': return t('auto_da_huy', 'Đã hủy')
    default: return status
  }
}`
);

fs.writeFileSync('src/views/admin/AdminFloorsView.vue', content, 'utf8');
console.log('AdminFloorsView updated.');
