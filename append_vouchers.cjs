const fs = require('fs');

function appendToExport(filename, newKeys) {
    let content = fs.readFileSync(filename, 'utf8');
    // find the last '}'
    const lastBraceIndex = content.lastIndexOf('}');
    if (lastBraceIndex !== -1) {
        content = content.slice(0, lastBraceIndex) + newKeys + "\n" + content.slice(lastBraceIndex);
        fs.writeFileSync(filename, content);
    }
}

const viKeys = `
  'vouchers.title': 'Quản lý Voucher',
  'vouchers.create': 'Tạo Voucher',
  'vouchers.createVoucher': 'Tạo mới Voucher',
  'vouchers.editVoucher': 'Chỉnh sửa Voucher',
  'vouchers.stats.active': 'Voucher đang hoạt động',
  'vouchers.stats.redeemed': 'Tổng số lượt dùng',
  'vouchers.stats.discountGiven': 'Tổng tiền đã giảm',
  'vouchers.stats.avgDiscount': 'Giảm trung bình/lượt',
  'vouchers.tabs.all': 'Tất cả',
  'vouchers.tabs.active': 'Đang hoạt động',
  'vouchers.tabs.expiringSoon': 'Sắp hết hạn',
  'vouchers.tabs.expired': 'Đã hết hạn',
  'vouchers.tabs.personalized': 'Cá nhân hóa',
  'vouchers.search': 'Tìm kiếm mã voucher...',
  'vouchers.empty': 'Chưa có voucher nào trong hệ thống',
  'vouchers.createFirst': 'Tạo voucher đầu tiên',
  'vouchers.form.code': 'Mã Voucher',
  'vouchers.form.type': 'Loại giảm giá',
  'vouchers.form.value': 'Giá trị giảm',
  'vouchers.form.minOrder': 'Đơn tối thiểu',
  'vouchers.form.maxDiscount': 'Giảm tối đa',
  'vouchers.form.validFrom': 'Hiệu lực từ',
  'vouchers.form.validUntil': 'Đến ngày',
  'vouchers.form.maxUses': 'Giới hạn sử dụng (Tổng)',
  'vouchers.form.usageLimitPerCustomer': 'Giới hạn sử dụng (Mỗi khách)',
  'vouchers.form.isPersonalized': 'Cá nhân hóa voucher',
  'vouchers.form.customerId': 'ID Khách hàng',
  'vouchers.form.description': 'Mô tả',
  'layout.voucher_management': 'Quản lý Voucher',
`;

const enKeys = `
  'vouchers.title': 'Voucher Management',
  'vouchers.create': 'Create Voucher',
  'vouchers.createVoucher': 'Create New Voucher',
  'vouchers.editVoucher': 'Edit Voucher',
  'vouchers.stats.active': 'Active Vouchers',
  'vouchers.stats.redeemed': 'Total Redeemed',
  'vouchers.stats.discountGiven': 'Total Discount Given',
  'vouchers.stats.avgDiscount': 'Avg Discount/Use',
  'vouchers.tabs.all': 'All',
  'vouchers.tabs.active': 'Active',
  'vouchers.tabs.expiringSoon': 'Expiring Soon',
  'vouchers.tabs.expired': 'Expired',
  'vouchers.tabs.personalized': 'Personalized',
  'vouchers.search': 'Search voucher code...',
  'vouchers.empty': 'No vouchers in the system yet',
  'vouchers.createFirst': 'Create first voucher',
  'vouchers.form.code': 'Voucher Code',
  'vouchers.form.type': 'Discount Type',
  'vouchers.form.value': 'Discount Value',
  'vouchers.form.minOrder': 'Minimum Order',
  'vouchers.form.maxDiscount': 'Maximum Discount',
  'vouchers.form.validFrom': 'Valid From',
  'vouchers.form.validUntil': 'Valid Until',
  'vouchers.form.maxUses': 'Usage Limit (Total)',
  'vouchers.form.usageLimitPerCustomer': 'Usage Limit (Per Customer)',
  'vouchers.form.isPersonalized': 'Personalize voucher',
  'vouchers.form.customerId': 'Customer ID',
  'vouchers.form.description': 'Description',
  'layout.voucher_management': 'Voucher Management',
`;

const jaKeys = `
  'vouchers.title': 'バウチャー管理',
  'vouchers.create': 'バウチャー作成',
  'vouchers.createVoucher': '新規バウチャー作成',
  'vouchers.editVoucher': 'バウチャー編集',
  'vouchers.stats.active': '有効なバウチャー',
  'vouchers.stats.redeemed': '合計利用回数',
  'vouchers.stats.discountGiven': '合計割引額',
  'vouchers.stats.avgDiscount': '平均割引額/回',
  'vouchers.tabs.all': 'すべて',
  'vouchers.tabs.active': '有効',
  'vouchers.tabs.expiringSoon': 'まもなく期限切れ',
  'vouchers.tabs.expired': '期限切れ',
  'vouchers.tabs.personalized': 'パーソナライズ',
  'vouchers.search': 'バウチャーコードを検索...',
  'vouchers.empty': 'システムにバウチャーがありません',
  'vouchers.createFirst': '最初のバウチャーを作成',
  'vouchers.form.code': 'バウチャーコード',
  'vouchers.form.type': '割引タイプ',
  'vouchers.form.value': '割引額',
  'vouchers.form.minOrder': '最低注文額',
  'vouchers.form.maxDiscount': '最大割引額',
  'vouchers.form.validFrom': '有効開始日',
  'vouchers.form.validUntil': '有効期限',
  'vouchers.form.maxUses': '利用制限（合計）',
  'vouchers.form.usageLimitPerCustomer': '利用制限（1人あたり）',
  'vouchers.form.isPersonalized': 'パーソナライズバウチャー',
  'vouchers.form.customerId': '顧客ID',
  'vouchers.form.description': '説明',
  'layout.voucher_management': 'バウチャー管理',
`;

appendToExport('src/locales/vi.ts', viKeys);
appendToExport('src/locales/en.ts', enKeys);
appendToExport('src/locales/ja.ts', jaKeys);
console.log('Appended vouchers to locales');
