const fs = require('fs');

function updateLocales() {
  const newKeys = {
    'vi': {
      auto_cap_nhat_ban: 'Cập nhật bàn',
      auto_tinh_trang: 'Tình trạng',
      auto_hoat_dong: 'Hoạt động',
      auto_bao_tri: 'Bảo trì',
      auto_ly_do_bao_tri: 'Lý do bảo trì',
      auto_nhap_ly_do: 'Nhập lý do...'
    },
    'en': {
      auto_cap_nhat_ban: 'Update Table',
      auto_tinh_trang: 'Status',
      auto_hoat_dong: 'Active',
      auto_bao_tri: 'Maintenance',
      auto_ly_do_bao_tri: 'Maintenance Reason',
      auto_nhap_ly_do: 'Enter reason...'
    },
    'ja': {
      auto_cap_nhat_ban: 'テーブル更新',
      auto_tinh_trang: 'ステータス',
      auto_hoat_dong: 'アクティブ',
      auto_bao_tri: 'メンテナンス',
      auto_ly_do_bao_tri: 'メンテナンスの理由',
      auto_nhap_ly_do: '理由を入力...'
    }
  };

  ['vi', 'en', 'ja'].forEach(lang => {
    const file = `src/locales/${lang}.ts`;
    let content = fs.readFileSync(file, 'utf8');
    for (const [k, v] of Object.entries(newKeys[lang])) {
      if (!content.includes(k)) {
        content = content.replace(/(export default \{)/, `$1\n  ${k}: '${v}',`);
      }
    }
    fs.writeFileSync(file, content);
  });
}
updateLocales();
console.log('Locales updated.');

let content = fs.readFileSync('src/views/admin/AdminFloorsView.vue', 'utf8');

// 1. Add isTableFormEditMode and update createTableForm
content = content.replace(
  /const createTableForm = ref\(\{ code: '', zone: '', capacity: 4 \}\);/g,
  `const isTableFormEditMode = ref(false);
const createTableForm = ref({ id: '', code: '', zone: '', capacity: 4, status: 'available', maintenanceReason: '' });`
);

// 2. Add openEditTableModal and update openCreateTableModal
content = content.replace(
  /function openCreateTableModal\(\) \{[\s\S]*?isCreateTableModalOpen\.value = true;\n\}/g,
  `function openCreateTableModal() {
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
}`
);

// 3. Change @click in the grid to call openEditTableModal
content = content.replace(
  /@click="openTableModal\(area\.name, table\)"/g,
  `@click="isEditModeEnabled ? openEditTableModal(area.name, table) : openTableModal(area.name, table)"`
);

// 4. Update saveNewTable function
const newSaveNewTable = `async function saveNewTable() {
  const { id, code, zone, capacity, status, maintenanceReason } = createTableForm.value;
  if (!code || !zone || !capacity) {
    Swal.fire('Lỗi', 'Vui lòng nhập đầy đủ Mã bàn, Phân khu và Sức chứa.', 'error');
    return;
  }
  const { branchId } = useAuth();
  const bid = branchId.value;
  if (!bid) {
    Swal.fire('Lỗi', 'Không tìm thấy thông tin Chi nhánh.', 'error');
    return;
  }

  let zoneId: string | null = null
  const trimmedZone = zone.trim()
  const { data: existingZone } = await supabase
    .from('zones')
    .select('id')
    .eq('branch_id', bid)
    .eq('name', trimmedZone)
    .maybeSingle()
  if (existingZone) {
    zoneId = existingZone.id
  } else {
    const { data: createdZone, error: zoneErr } = await supabase
      .from('zones')
      .insert({
        branch_id: bid,
        name: trimmedZone,
        sort_order: 99,
        is_active: true,
      })
      .select('id')
      .single()
    if (zoneErr || !createdZone) {
      Swal.fire('Lỗi', 'Không thể tạo Phân khu mới: ' + (zoneErr?.message ?? ''), 'error')
      return
    }
    zoneId = createdZone.id
  }

  if (isTableFormEditMode.value) {
    const { error } = await supabase.from('tables').update({
      zone_id: zoneId,
      code,
      capacity,
      status: status,
      metadata: status === 'maintenance' ? { maintenance_reason: maintenanceReason } : {}
    }).eq('id', id);

    if (error) {
      console.error(error);
      Swal.fire('Lỗi', 'Không thể cập nhật bàn: ' + error.message, 'error');
      return;
    }
    Swal.fire('Thành công', 'Đã cập nhật bàn', 'success');
  } else {
    const { error } = await supabase.from('tables').insert([{
      branch_id: bid,
      zone_id: zoneId,
      code,
      capacity,
      status: status,
      is_active: true,
      metadata: status === 'maintenance' ? { maintenance_reason: maintenanceReason } : {}
    }]);

    if (error) {
      console.error(error);
      Swal.fire('Lỗi', 'Không thể tạo bàn mới: ' + error.message, 'error');
      return;
    }
    Swal.fire('Thành công', 'Đã tạo bàn mới', 'success');
  }

  isCreateTableModalOpen.value = false;
  await loadTables();
}`;

content = content.replace(
  /async function saveNewTable\(\) \{[\s\S]*?isCreateTableModalOpen\.value = false;\s*await loadTables\(\);\s*\}/m,
  newSaveNewTable
);

// 5. Update the modal template for createTableForm
const newModalHeader = `<h3
          class="text-base font-black text-gray-900 tracking-tight mb-3 flex items-center gap-1 border-b border-gray-100 pb-2 select-none"
        >
          <span>✏️</span> {{ isTableFormEditMode ? t("auto_cap_nhat_ban") : t("auto_th_m_b_n_m_i") }}
        </h3>`;
content = content.replace(
  /<h3[\s\S]*?<span>✨<\/span>\s*\{\{\s*t\("auto_th_m_b_n_m_i"\)\s*\}\}\s*<\/h3>/m,
  newModalHeader
);

const capacityField = `<div class="space-y-1">
            <label
              class="text-[9px] font-black text-gray-400 uppercase select-none"
              >{{ t("auto_s_c_ch_a_s_ng_i") }}</label
            >
            <input
              type="number"
              v-model="createTableForm.capacity"
              placeholder="VD: 4"
              min="1"
              class="w-full bg-gray-50 border border-gray-200 rounded-lg px-2.5 py-2 font-bold text-gray-850 focus:outline-none focus:ring-1 focus:ring-[#FF7B89]"
            />
          </div>`;

const newFields = `${capacityField}
          <div class="space-y-1">
            <label class="text-[9px] font-black text-gray-400 uppercase select-none">{{ t("auto_tinh_trang") }}</label>
            <select v-model="createTableForm.status" class="w-full bg-gray-50 border border-gray-200 rounded-lg px-2.5 py-2 font-bold text-gray-850 focus:outline-none focus:ring-1 focus:ring-[#FF7B89]">
              <option value="available">{{ t("auto_hoat_dong") }}</option>
              <option value="maintenance">{{ t("auto_bao_tri") }}</option>
            </select>
          </div>
          <div v-if="createTableForm.status === 'maintenance'" class="space-y-1">
            <label class="text-[9px] font-black text-gray-400 uppercase select-none">{{ t("auto_ly_do_bao_tri") }}</label>
            <input type="text" v-model="createTableForm.maintenanceReason" :placeholder="t('auto_nhap_ly_do')" class="w-full bg-gray-50 border border-gray-200 rounded-lg px-2.5 py-2 font-bold text-gray-850 focus:outline-none focus:ring-1 focus:ring-[#FF7B89]" />
          </div>`;

content = content.replace(capacityField, newFields);

// Fix "Tạo bàn mới" button text
const oldSubmitButton = `{{ t("auto_t_o_b_n_m_i") }}`;
const newSubmitButton = `{{ isTableFormEditMode ? t("auto_cap_nhat_ban") : t("auto_t_o_b_n_m_i") }}`;
content = content.replace(oldSubmitButton, newSubmitButton);

fs.writeFileSync('src/views/admin/AdminFloorsView.vue', content);
console.log('AdminFloorsView.vue updated successfully.');
