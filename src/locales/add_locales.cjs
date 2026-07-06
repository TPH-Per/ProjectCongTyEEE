const fs = require('fs')

const files = {
  vi: 'src/locales/vi.ts',
  en: 'src/locales/en.ts',
  ja: 'src/locales/ja.ts'
}

const keys = {
  vi: {
    'layout.overview': 'Tổng quan',
    'layout.account_management': 'Quản lý tài khoản',
    'layout.branch_management': 'Quản lý chi nhánh',
    'layout.integrations': 'Tích hợp hệ thống',
    'layout.system_administration': 'Quản trị hệ thống',
    'layout.system': 'Hệ thống',
    'layout.system_overview': 'Tổng quan hệ thống',
    'layout.data_configuration': 'Cấu hình dữ liệu',
    'layout.menu_management': 'Quản lý Menu',
    'layout.floor_plan': 'Sơ đồ phòng/bàn',
    'layout.kpi_kgi_configuration': 'Cấu hình KPI/KGI',
    'layout.system_audit_log': 'Nhật ký hệ thống',
    'branch.title': 'Quản lý Chi Nhánh',
    'branch.add': 'Thêm chi nhánh',
    'branch.edit': 'Chỉnh sửa',
    'branch.deactivate': 'Vô hiệu hóa',
    'branch.name': 'Tên chi nhánh',
    'branch.address': 'Địa chỉ',
    'branch.phone': 'Điện thoại',
    'branch.capacity': 'Sức chứa',
    'branch.manager': 'Quản lý (ID)',
    'common.all': 'Tất cả',
    'common.active': 'Đang hoạt động',
    'common.inactive': 'Ngừng hoạt động',
  },
  en: {
    'layout.overview': 'Overview',
    'layout.account_management': 'Account Management',
    'layout.branch_management': 'Branch Management',
    'layout.integrations': 'Integrations',
    'layout.system_administration': 'System Administration',
    'layout.system': 'System',
    'layout.system_overview': 'System Overview',
    'layout.data_configuration': 'Data Configuration',
    'layout.menu_management': 'Menu Management',
    'layout.floor_plan': 'Floor Plan',
    'layout.kpi_kgi_configuration': 'KPI/KGI Configuration',
    'layout.system_audit_log': 'System Audit Log',
    'branch.title': 'Branch Management',
    'branch.add': 'Add Branch',
    'branch.edit': 'Edit',
    'branch.deactivate': 'Deactivate',
    'branch.name': 'Branch Name',
    'branch.address': 'Address',
    'branch.phone': 'Phone',
    'branch.capacity': 'Capacity',
    'branch.manager': 'Manager (ID)',
    'common.all': 'All',
    'common.active': 'Active',
    'common.inactive': 'Inactive',
  },
  ja: {
    'layout.overview': '概要',
    'layout.account_management': 'アカウント管理',
    'layout.branch_management': '支店管理',
    'layout.integrations': '統合',
    'layout.system_administration': 'システム管理',
    'layout.system': 'システム',
    'layout.system_overview': 'システム概要',
    'layout.data_configuration': 'データ設定',
    'layout.menu_management': 'メニュー管理',
    'layout.floor_plan': 'フロアプラン',
    'layout.kpi_kgi_configuration': 'KPI/KGI設定',
    'layout.system_audit_log': 'システム監査ログ',
    'branch.title': '支店管理',
    'branch.add': '支店を追加',
    'branch.edit': '編集',
    'branch.deactivate': '無効化',
    'branch.name': '支店名',
    'branch.address': '住所',
    'branch.phone': '電話番号',
    'branch.capacity': '収容人数',
    'branch.manager': 'マネージャー (ID)',
    'common.all': 'すべて',
    'common.active': 'アクティブ',
    'common.inactive': '非アクティブ',
  }
}

for (const [lang, path] of Object.entries(files)) {
  let content = fs.readFileSync(path, 'utf8')
  // Find the last closing brace
  const lastBraceIndex = content.lastIndexOf('}')
  if (lastBraceIndex !== -1) {
    content = content.substring(0, lastBraceIndex)
  }
  // check if missing trailing comma
  if (!content.trim().endsWith(',')) {
    content += ','
  }
  
  for (const [key, val] of Object.entries(keys[lang])) {
    if (!content.includes(`'${key}'`)) {
      content += `\n  '${key}': '${val.replace(/'/g, "\\'")}',`
    }
  }
  
  content += '\n}\n'
  fs.writeFileSync(path, content, 'utf8')
}
