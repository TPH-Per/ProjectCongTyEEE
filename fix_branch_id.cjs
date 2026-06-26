const fs = require('fs');

let content = fs.readFileSync('src/views/admin/AdminAccountsView.vue', 'utf8');

// For create_user
content = content.replace(/branch_id: form.value.branch_id\s*\n/, 'branch_id: form.value.branch_id || null\n');
// For update_user
content = content.replace(/branch_id: form.value.branch_id,\s*\n\s*is_active/, 'branch_id: form.value.branch_id || null,\n              is_active');

fs.writeFileSync('src/views/admin/AdminAccountsView.vue', content, 'utf8');
console.log('Fixed branch_id empty string issue in AdminAccountsView.vue');
