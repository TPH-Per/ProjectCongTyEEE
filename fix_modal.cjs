const fs = require('fs');
let content = fs.readFileSync('src/views/admin/AdminFloorsView.vue', 'utf8');

const newCapacity = `<div class="space-y-1">
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
          </div>
          <div class="space-y-1" v-if="isTableFormEditMode">
            <label class="text-[9px] font-black text-gray-400 uppercase select-none">{{ t("auto_tinh_trang") }}</label>
            <select v-model="createTableForm.status" class="w-full bg-gray-50 border border-gray-200 rounded-lg px-2.5 py-2 font-bold text-gray-850 focus:outline-none focus:ring-1 focus:ring-[#FF7B89]">
              <option value="available">{{ t("auto_hoat_dong") }}</option>
              <option value="maintenance">{{ t("auto_bao_tri") }}</option>
            </select>
          </div>
          <div class="space-y-1" v-if="isTableFormEditMode && createTableForm.status === 'maintenance'">
            <label class="text-[9px] font-black text-gray-400 uppercase select-none">{{ t("auto_ly_do_bao_tri") }}</label>
            <input type="text" v-model="createTableForm.maintenanceReason" :placeholder="t('auto_nhap_ly_do')" class="w-full bg-gray-50 border border-gray-200 rounded-lg px-2.5 py-2 font-bold text-gray-850 focus:outline-none focus:ring-1 focus:ring-[#FF7B89]" />
          </div>`;

content = content.replace(/<div class="space-y-1">\s*<label\s*class="text-\[9px\] font-black text-gray-400 uppercase select-none"\s*>\s*\{\{\s*t\("auto_s_c_ch_a_s_ng_i"\)\s*\}\}\s*<\/label>\s*<input\s*type="number"\s*v-model="createTableForm.capacity"[\s\S]*?<\/div>/m, newCapacity);

content = content.replace(/\{\{\s*t\("auto_th_m_b_n_m_i"\)\s*\}\}\s*<\/h3>/g, '{{ isTableFormEditMode ? t("auto_cap_nhat_ban") : t("auto_th_m_b_n_m_i") }}\n        </h3>');
content = content.replace(/\{\{\s*t\("auto_t_o_b_n_m_i"\)\s*\}\}\s*<\/button>/g, '{{ isTableFormEditMode ? t("auto_cap_nhat_ban") : t("auto_t_o_b_n_m_i") }}\n          </button>');

fs.writeFileSync('src/views/admin/AdminFloorsView.vue', content);
console.log('Fixed modal');
