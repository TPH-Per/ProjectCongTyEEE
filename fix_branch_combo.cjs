const fs = require('fs');

let content = fs.readFileSync('src/views/admin/AdminAccountsView.vue', 'utf8');

// 1. Replace the input with a select
const inputHtml = `<input v-model="form.branch_id" type="text" class="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-gray-900" />`;
const selectHtml = `<select v-model="form.branch_id" class="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-gray-900 bg-white">
              <option value="" disabled>{{ t('auto_chon_chi_nhanh', 'Chọn chi nhánh') }}</option>
              <option v-for="b in branches" :key="b.id" :value="b.id">{{ b.name }}</option>
            </select>`;
content = content.replace(inputHtml, selectHtml);

// 2. Add branches state
const stateInsert = `const form = ref({
  id: '',
  full_name: '',
  email: '',
  role: 'staff',
  password: '',
  branch_id: branchId.value || DEFAULT_BRANCH_ID,
})

const branches = ref<any[]>([])`;

content = content.replace(/const form = ref\(\{[\s\S]*?\}\)/, stateInsert);

// 3. Fetch branches on mount
const fetchInsert = `
const fetchBranches = async () => {
  try {
    const { data, error: err } = await supabase.from('branches').select('id, name').order('name')
    if (err) throw err
    branches.value = data || []
  } catch (e: any) {
    console.error('Error fetching branches:', e.message)
  }
}

onMounted(() => {
  fetchAccounts()
  fetchBranches()
})
`;

content = content.replace(/onMounted\(\(\) => \{\s*fetchAccounts\(\)\s*\}\)/, fetchInsert);

// 4. Also rename the label "Chi nhánh (Branch ID)" to just "Chi nhánh (Branch)"
content = content.replace(/auto_chi_nh_nh_branch_id/g, 'auto_chi_nhanh_branch');

fs.writeFileSync('src/views/admin/AdminAccountsView.vue', content, 'utf8');
console.log('Updated AdminAccountsView.vue');
