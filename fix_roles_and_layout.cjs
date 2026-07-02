const fs = require('fs');

let f1 = fs.readFileSync('src/views/admin/AdminAccountsView.vue', 'utf8');

// Replace role options in select (the filter dropdown)
f1 = f1.replace(
  /<option value="admin">{{ t\('admin_accounts\.roles\.system_admin'\) \|\| 'Admin' }}<\/option>[\s\S]*?<option value="accounting">Accounting<\/option>/m,
  \<option value="superadmin">Superadmin</option>
        <option value="manager">Manager</option>
        <option value="reception">Reception</option>
        <option value="staff">Staff</option>
        <option value="procurement_manager">Procurement Manager</option>
        <option value="procurement_staff">Procurement Staff</option>
        <option value="accountant">Accountant</option>
        <option value="crm_manager">CRM Manager</option>
        <option value="marketing">Marketing</option>\
);

// Replace role display in table
f1 = f1.replace(
  /<span v-if="user\.role === 'admin'"[\s\S]*?<span v-else class="px-2\.5 py-1 rounded-md text-xs font-bold bg-orange-100 text-orange-700 border border-orange-200">Staff<\/span>/m,
  \<span class="px-2.5 py-1 rounded-md text-xs font-bold border"
                :class="{
                  'bg-gray-900 text-white': user.role === 'superadmin',
                  'bg-blue-100 text-blue-700 border-blue-200': user.role === 'manager',
                  'bg-purple-100 text-purple-700 border-purple-200': user.role === 'reception',
                  'bg-emerald-100 text-emerald-700 border-emerald-200': user.role.startsWith('procurement'),
                  'bg-red-100 text-red-700 border-red-200': user.role === 'accountant',
                  'bg-orange-100 text-orange-700 border-orange-200': user.role === 'staff'
                }">
                {{ user.role }}
              </span>\
);

// Replace role options in form select
f1 = f1.replace(
  /<option value="admin">System Admin<\/option>[\s\S]*?<option value="accounting">Accounting \(K\? ton\)<\/option>/m,
  \<option value="superadmin">Superadmin</option>
              <option value="manager">Manager</option>
              <option value="reception">Reception</option>
              <option value="staff">Staff</option>
              <option value="procurement_manager">Procurement Manager</option>
              <option value="procurement_staff">Procurement Staff</option>
              <option value="accountant">Accountant</option>
              <option value="crm_manager">CRM Manager</option>
              <option value="marketing">Marketing</option>\
);

fs.writeFileSync('src/views/admin/AdminAccountsView.vue', f1);

// Now for DashboardLayout.vue
let f2 = fs.readFileSync('src/layouts/DashboardLayout.vue', 'utf8');
f2 = f2.replace(
  /<button class="p-1 rounded-lg hover:bg-white text-\[hsl\(var\(--muted-foreground\)\)\]">[\s\S]*?<\/button>/m,
  \<button class="flex items-center gap-2 p-1 px-2 rounded-lg hover:bg-white hover:text-red-600 text-[hsl(var(--muted-foreground))] transition-colors" @click="handleSignOut">
            <LogOut :size="13" />
            <span class="text-xs font-semibold">{{ t('layout.logout', 'Đăng xuất') }}</span>
          </button>\
);

// We need to add handleSignOut to DashboardLayout.vue if it's missing
if (!f2.includes('function handleSignOut()')) {
  f2 = f2.replace(
    /const { t } = useI18n\(\)/,
    \const { t } = useI18n()
const { signOut } = useAuth()
const router = useRouter()

async function handleSignOut() {
  await signOut()
  await router.push({ name: 'login' })
}\
  );
  if (!f2.includes('useRouter')) {
    f2 = f2.replace(/from 'vue-router'/, ", useRouter } from 'vue-router'");
  }
}

fs.writeFileSync('src/layouts/DashboardLayout.vue', f2);

