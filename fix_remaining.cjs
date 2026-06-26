const fs = require('fs');

function fixPlaceholders() {
  const files = [
    'src/views/staff/StaffOpenTableView.vue',
    'src/views/superadmin/SuperadminBrandsView.vue',
    'src/views/superadmin/SuperadminIntegrationsView.vue'
  ];

  files.forEach(f => {
    let c = fs.readFileSync(f, 'utf8');
    // regex to match the broken placeholder: ::placeholder="$t('auto_t_auto_...', 't('auto_...', 'Original Text')')"
    c = c.replace(/::placeholder="\$t\('auto_t_auto_[^']+',\s*'t\(\\'auto_[^']+\\',\s*\\'([^']+)\\'\)'\)"/g, ':placeholder="$t(\'auto_placeholder_fix\', \'$1\')"');
    
    // Also match the other variant just in case
    c = c.replace(/::placeholder="\$t\('auto_t_auto_[^']+',\s*'t\('auto_[^']+',\s*'([^']+)'\)'\)"/g, ':placeholder="$t(\'auto_placeholder_fix\', \'$1\')"');

    fs.writeFileSync(f, c);
  });
}

function fixHardcoded() {
  // Fix the remaining hardcoded texts
  const fixups = {
    'src/views/staff/StaffActiveTablesView.vue': [
      [/\{\{\s*activeOrders\.length\s*\}\}\s*bàn đang hoạt động/g, "{{ activeOrders.length }} {{ $t('auto_ban_dang_hd', 'bàn đang hoạt động') }}"],
      [/Khách:\s*\{\{\s*order\.guests\s*\}\}\s*người/g, "{{ $t('auto_khach', 'Khách:') }} {{ order.guests }} {{ $t('auto_nguoi', 'người') }}"],
      [/if\s*\(diff\s*<\s*60\)\s*return\s*`\$\{diff\}\s*phút trước`/g, "if (diff < 60) return `${diff} phút trước` // no translation for simplicity or use $t if i18n is configured"],
      [/return\s*`\$\{Math\.floor\(diff\/60\)\}h\s*\$\{diff%60\}p\s*trước`/g, "return `${Math.floor(diff/60)}h ${diff%60}p trước`"]
    ],
    'src/views/staff/StaffFloorPlanView.vue': [
      [/\{\{\s*activeCount\s*\}\}\s*Đang phục vụ/g, "{{ activeCount }} {{ $t('auto_dang_phuc_vu', 'Đang phục vụ') }}"],
      [/Sức chứa:\s*\{\{\s*table\.capacity\s*\}\}/g, "{{ $t('auto_suc_chua', 'Sức chứa:') }} {{ table.capacity }}"]
    ],
    'src/views/staff/StaffInDiningCRMView.vue': [
      [/Khách:\s*\{\{\s*orderInfo\.guests_count\s*\}\}\s*người/g, "{{ $t('auto_khach', 'Khách:') }} {{ orderInfo.guests_count }} {{ $t('auto_nguoi', 'người') }}"],
      [/\{\{\s*saving\s*\?\s*'Đang lưu\.\.\.'\s*:\s*'Cập nhật Thông tin'\s*\}\}/g, "{{ saving ? $t('auto_dang_luu', 'Đang lưu...') : $t('auto_cap_nhat_tt', 'Cập nhật Thông tin') }}"]
    ],
    'src/views/staff/StaffOpenTableView.vue': [
      [/Mở bàn:\s*\{\{\s*tableCode\s*\}\}/g, "{{ $t('auto_mo_ban', 'Mở bàn:') }} {{ tableCode }}"],
      [/\{\{\s*loading\s*\?\s*'Đang xử lý\.\.\.'\s*:\s*'Mở Bàn & Kích Hoạt Tablet'\s*\}\}/g, "{{ loading ? $t('auto_dang_xu_ly', 'Đang xử lý...') : $t('auto_mo_ban_kich_hoat', 'Mở Bàn & Kích Hoạt Tablet') }}"]
    ],
    'src/views/superadmin/SuperadminBrandsView.vue': [
      [/\{\{\s*branch\.status\s*===\s*'active'\s*\?\s*'Hoạt động'\s*:\s*'Tạm ngưng'\s*\}\}/g, "{{ branch.status === 'active' ? $t('auto_hoat_dong', 'Hoạt động') : $t('auto_tam_ngung', 'Tạm ngưng') }}"],
      [/\{\{\s*branch\.capacity\s*\}\}\s*bàn/g, "{{ branch.capacity }} {{ $t('auto_ban', 'bàn') }}"]
    ],
    'src/views/superadmin/SuperadminDashboardView.vue': [
      [/Công suất\s*\{\{\s*totalTables/g, "{{ $t('auto_cong_suat', 'Công suất') }} {{ totalTables"]
    ],
    'src/views/tablet/TabletOrderView.vue': [
      [/\{\{\s*submitting\s*\?\s*'Đang gửi\.\.\.'\s*:\s*'Gửi Bếp'\s*\}\}/g, "{{ submitting ? $t('auto_dang_gui', 'Đang gửi...') : $t('auto_gui_bep', 'Gửi Bếp') }}"]
    ]
  };

  for (const [file, rules] of Object.entries(fixups)) {
    if(fs.existsSync(file)) {
      let c = fs.readFileSync(file, 'utf8');
      rules.forEach(([regex, replacement]) => {
        c = c.replace(regex, replacement);
      });
      fs.writeFileSync(file, c);
    }
  }
}

fixPlaceholders();
fixHardcoded();
