import re

file_path = r'C:\Users\Per\Downloads\noMoreF2TECH\src\views\admin\AdminFloorsView.vue'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add new table button
new_button = '''      <!-- Khu vực đang chọn hiện tại -->
      <div class="flex items-center gap-2 select-none">
        <span class="text-xs font-bold text-gray-400 uppercase tracking-wider">{{ t('auto__ang_xem_') }}</span>
        <div class="bg-pink-50 border border-pink-100 text-[#FF7B89] px-3 py-1.5 rounded-xl text-xs font-black flex items-center gap-2 shadow-sm">
          <span>📍 {{ selectedZoneLabel }}</span>
          <span class="text-[9px] bg-[#FF7B89] text-white px-1.5 py-0.5 rounded-full font-black">
            {{ getZoneTableCount(selectedZone) }} bàn
          </span>
        </div>
      </div>
      
      <!-- New Add Table Button -->
      <button @click="openAddTableModal" class="ml-auto bg-emerald-600 hover:bg-emerald-700 text-white px-3.5 py-2 rounded-xl text-xs font-black shadow-sm active:scale-95 transition-all flex items-center gap-1">
        <span>+</span> Thêm Bàn
      </button>
    </div>'''
content = re.sub(r'      <!-- Khu vực đang chọn hiện tại -->.*?</div>\s*</div>', new_button, content, flags=re.DOTALL)

# 2. Add Edit button in Modal 1
edit_btn = '''          <div class="flex gap-3 pt-3.5 border-t border-gray-100 mt-4">
            <button 
              @click="openEditTableModal(selectedTableForModal, selectedTableForModal.areaName)"
              class="flex-1 py-2 rounded-xl border border-blue-200 bg-blue-50 hover:bg-blue-100 text-blue-700 text-[11px] font-bold transition-colors select-none"
            >
              Chỉnh sửa
            </button>
            <button 
              @click="closeTableModal"
              class="flex-1 py-2 rounded-xl border border-gray-250 bg-white hover:bg-gray-50 text-gray-700 text-[11px] font-bold transition-colors select-none"
            >
              Đóng
            </button>
            <button 
              @click="saveTableModal"
              class="flex-1 py-2 rounded-xl bg-[#FF7B89] hover:bg-[#FF5A6E] text-white text-[11px] font-black transition-colors shadow-sm select-none"
            >
              Lưu Lại
            </button>
          </div>'''
content = re.sub(r'          <div class="flex gap-3 pt-3.5 border-t border-gray-100 mt-4">\s*<button\s*@click="closeTableModal".*?</button>\s*</div>', edit_btn, content, flags=re.DOTALL)

# 3. Add Modal 7
modal_7 = '''    <!-- MODAL 7: ADD / EDIT TABLE -->
    <div v-if="isAddEditTableModalOpen" class="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div class="fixed inset-0 bg-gray-900/60 backdrop-blur-sm" @click="isAddEditTableModalOpen = false"></div>
      
      <div class="bg-white border-2 border-emerald-100 rounded-3xl w-full max-w-sm shadow-2xl p-6 z-10 relative animate-fade-in text-xs font-bold text-gray-700">
        <button @click="isAddEditTableModalOpen = false" class="absolute top-4 right-4 w-8 h-8 rounded-full bg-gray-100 hover:bg-gray-200 text-gray-500 hover:text-gray-800 flex items-center justify-center transition-colors font-bold text-sm select-none">
          ✕
        </button>

        <h3 class="text-lg font-black text-gray-900 tracking-tight mb-4 flex items-center gap-1.5 select-none border-b border-gray-100 pb-2">
          <span>🪑</span> {{ isEditTableMode ? 'Chỉnh Sửa Bàn' : 'Thêm Bàn Mới' }}
        </h3>

        <div class="space-y-3.5 mb-5">
          <div class="space-y-1">
            <label class="text-[9px] font-black text-gray-400 uppercase">Mã bàn</label>
            <input 
              type="text" 
              v-model="addEditTableForm.code"
              placeholder="VD: A01"
              class="w-full bg-gray-50 border border-gray-200 rounded-lg px-2.5 py-2 font-bold text-gray-800 focus:outline-none focus:ring-1 focus:ring-emerald-500"
            />
          </div>

          <div class="grid grid-cols-2 gap-3.5">
            <div class="space-y-1">
              <label class="text-[9px] font-black text-gray-400 uppercase">Sức chứa (người)</label>
              <input 
                type="number" 
                v-model="addEditTableForm.capacity"
                placeholder="4"
                class="w-full bg-gray-50 border border-gray-200 rounded-lg px-2.5 py-2 font-bold text-gray-800 focus:outline-none focus:ring-1 focus:ring-emerald-500"
              />
            </div>
            <div class="space-y-1">
              <label class="text-[9px] font-black text-gray-400 uppercase">Phân khu (Zone)</label>
              <input 
                type="text" 
                v-model="addEditTableForm.zone"
                placeholder="VD: Khu A"
                class="w-full bg-gray-50 border border-gray-200 rounded-lg px-2.5 py-2 font-bold text-gray-800 focus:outline-none focus:ring-1 focus:ring-emerald-500"
              />
            </div>
          </div>

          <div class="space-y-1">
            <label class="text-[9px] font-black text-gray-400 uppercase">Trạng thái</label>
            <select 
              v-model="addEditTableForm.status"
              class="w-full bg-gray-50 border border-gray-200 rounded-lg px-2.5 py-2 font-bold text-gray-800 focus:outline-none focus:ring-1 focus:ring-emerald-500"
            >
              <option value="available">Trống</option>
              <option value="reserved">Đặt trước</option>
              <option value="occupied">Phục vụ</option>
              <option value="maintenance">Bảo trì</option>
            </select>
          </div>
        </div>

        <div class="flex gap-3 select-none">
          <button 
            @click="isAddEditTableModalOpen = false"
            class="flex-1 py-2 rounded-xl border border-gray-250 bg-white hover:bg-gray-50 text-gray-700 text-[11px] font-bold transition-colors"
          >
            Hủy Bỏ
          </button>
          <button 
            @click="saveAddEditTable"
            class="flex-1 py-2 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white text-[11px] font-black transition-colors shadow-sm"
          >
            {{ isEditTableMode ? 'Cập Nhật' : 'Lưu Bàn' }}
          </button>
        </div>
      </div>
    </div>

  </div>
</template>'''
content = content.replace('  </div>\n</template>', modal_7)

# 4. Imports and Interface
imports_new = '''<script setup lang="ts">
import { useI18n } from 'vue-i18n'
const { t } = useI18n()
import { ref, computed, onMounted, onUnmounted } from 'vue';
import { supabase } from '@/lib/supabase';
import { useAuth } from '@/composables/useAuth';
import type { TableRow, BranchRow } from '@/types/database';

interface TableInfo {
  id?: string;
  code: string;
  status: 'Available' | 'Reserved' | 'Arrived' | 'Serving';
  capacity: number;
  customerName?: string;
  billAmount?: string;
  occupiedDuration?: string;
  checkInTime?: string;
}'''
content = re.sub(r'<script setup lang="ts">\nimport { useI18n } from \'vue-i18n\'\nconst \{ t \} = useI18n\(\)\nimport { ref, computed, onMounted, onUnmounted } from \'vue\';\n\ninterface TableInfo \{\n  code: string;\n  status: \'Available\' \| \'Reserved\' \| \'Arrived\' \| \'Serving\';\n  capacity: number;\n  customerName\?: string;\n  billAmount\?: string;\n  occupiedDuration\?: string;\n  checkInTime\?: string;\n\}', imports_new, content, flags=re.DOTALL)

# 5. Fetch logic and areas
fetch_logic = '''// Bottom Dashboard Zone list order
const dashboardZoneList = [
  { label: 'Tất cả', value: 'All' },
  { label: 'Mang đi', value: 'Khu Catalog' },
  { label: 'Khu A', value: 'Khu A' },
  { label: 'Khu B', value: 'Khu B' },
  { label: 'Khu C', value: 'Khu C' },
  { label: 'Khu R', value: 'Khu R' },
  { label: 'Khu T', value: 'Khu T' },
  { label: 'Capichi', value: 'Khu Capichi' },
  { label: 'Shopee', value: 'Khu Shopee' },
  { label: 'beFood', value: 'Khu BE' },
  { label: 'GrabFood', value: 'Khu Grab' }
];

const { branchId } = useAuth();
const rawTables = ref<TableRow[]>([]);
const rawBranches = ref<BranchRow[]>([]);

const areas = ref<AreaInfo[]>([]);

async function fetchData() {
  if (!branchId.value) return;
  const [{ data: tables }, { data: branches }] = await Promise.all([
    supabase.from('tables').select('*').eq('branch_id', branchId.value),
    supabase.from('branches').select('*')
  ]);
  if (tables) rawTables.value = tables;
  if (branches) rawBranches.value = branches;
  updateAreas();
}

function updateAreas() {
  const areaMap = new Map<string, TableInfo[]>();
  
  rawTables.value.forEach(t => {
    let sStatus: 'Available' | 'Reserved' | 'Arrived' | 'Serving' = 'Available';
    if (t.status === 'available') sStatus = 'Available';
    else if (t.status === 'reserved') sStatus = 'Reserved';
    else if (t.status === 'occupied') sStatus = 'Serving';
    
    const tableInfo: TableInfo = {
      id: t.id,
      code: t.code,
      capacity: t.capacity,
      status: sStatus,
    };
    
    if (!areaMap.has(t.zone)) {
      areaMap.set(t.zone, []);
    }
    areaMap.get(t.zone)!.push(tableInfo);
  });
  
  areas.value = Array.from(areaMap.entries()).map(([name, tables]) => ({
    name,
    description: name,
    tables
  }));
}'''
content = re.sub(r'// Bottom Dashboard Zone list order.*?const areas = ref<AreaInfo\[\]>\(\[.*?\]\);', fetch_logic, content, flags=re.DOTALL)

# 6. onMounted logic
onmounted_logic = '''onMounted(() => {
  updateSystemClock();
  systemClockInterval = setInterval(updateSystemClock, 1000) as unknown as number;
  resetToRealTimeOnly();
  fetchData();
});'''
content = re.sub(r'onMounted\(\(\) => \{\n  updateSystemClock\(\);\n  systemClockInterval = setInterval\(updateSystemClock, 1000\) as unknown as number;\n  resetToRealTimeOnly\(\);\n\}\);', onmounted_logic, content)

# 7. Add Add/Edit Table Modal state logic
modal_7_logic = '''const isAddEditTableModalOpen = ref(false);
const isEditTableMode = ref(false);
const editingTableId = ref('');
const addEditTableForm = ref({
  code: '',
  capacity: 4,
  zone: 'Khu A',
  status: 'available'
});

function openAddTableModal() {
  isEditTableMode.value = false;
  editingTableId.value = '';
  addEditTableForm.value = {
    code: '',
    capacity: 4,
    zone: 'Khu A',
    status: 'available'
  };
  isAddEditTableModalOpen.value = true;
}

function openEditTableModal(table: any, areaName: string) {
  isEditTableMode.value = true;
  editingTableId.value = table.id || '';
  addEditTableForm.value = {
    code: table.code,
    capacity: table.capacity,
    zone: areaName,
    status: table.status === 'Available' ? 'available' : table.status === 'Reserved' ? 'reserved' : table.status === 'Serving' ? 'occupied' : 'available'
  };
  isAddEditTableModalOpen.value = true;
  isTableModalOpen.value = false; // Close detail modal
}

async function saveAddEditTable() {
  if (!branchId.value) return;
  
  const payload = {
    branch_id: branchId.value,
    code: addEditTableForm.value.code,
    capacity: addEditTableForm.value.capacity,
    zone: addEditTableForm.value.zone,
    status: addEditTableForm.value.status as any,
    shape: 'rectangle' as any,
    pos_x: 0,
    pos_y: 0,
    is_active: true,
    metadata: {}
  };

  if (isEditTableMode.value && editingTableId.value) {
    await supabase.from('tables').update(payload).eq('id', editingTableId.value);
  } else {
    await supabase.from('tables').insert(payload);
  }
  
  isAddEditTableModalOpen.value = false;
  await fetchData();
}

const resetToCurrentState = () => {'''
content = content.replace('const resetToCurrentState = () => {', modal_7_logic)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print('Done editing!')
