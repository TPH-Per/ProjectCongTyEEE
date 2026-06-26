const fs = require('fs');
let content = fs.readFileSync('src/views/admin/AdminFloorsView.vue', 'utf8');

const newOpenFns = `function openCreateTableModal() {
  isTableFormEditMode.value = false;
  createTableForm.value = { id: '', code: '', zone: selectedZone.value !== 'All' ? selectedZone.value : '', capacity: 4, status: 'available', maintenanceReason: '' };
  isCreateTableModalOpen.value = true;
}

function openEditTableModal(areaName: string, table: any) {
  isTableFormEditMode.value = true;
  createTableForm.value = { 
    id: table.id, 
    code: table.code, 
    zone: areaName, 
    capacity: table.capacity || 4, 
    status: table.status.toLowerCase(), 
    maintenanceReason: table.metadata?.maintenance_reason || '' 
  };
  isCreateTableModalOpen.value = true;
}`;

content = content.replace(/function openCreateTableModal\(\) \{[\s\S]*?isCreateTableModalOpen\.value = true;\r?\n\}/m, newOpenFns);
fs.writeFileSync('src/views/admin/AdminFloorsView.vue', content);
