const fs = require('fs');

function addKeys(filePath, newKeys) {
  let content = fs.readFileSync(filePath, 'utf8');
  
  const formattedKeys = Object.entries(newKeys).map(([k, v]) => "  '" + k + "': '" + v + "',").join('\n');
  
  // Find the last closing brace that ends the export default { ... }
  content = content.replace(/(};?\s*)$/m, formattedKeys + '\n$1');
  
  fs.writeFileSync(filePath, content);
}

const keysVi = {
  'vouchers.title': 'Quản lý Voucher',
  'vouchers.create': 'Tạo Voucher',
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
  'vouchers.noExpiry': 'Không giới hạn',
  'vouchers.createVoucher': 'Tạo mới Voucher',
  'vouchers.form.code': 'Mã Voucher',
  'vouchers.form.type': 'Loại giảm giá',
  'vouchers.form.validFrom': 'Hiệu lực từ',
  'vouchers.form.validUntil': 'Hiệu lực đến',
  'vouchers.form.maxUses': 'Số lần dùng tối đa',
  'vouchers.form.usageLimitPerCustomer': 'Giới hạn mỗi khách hàng',
  'vouchers.form.isPersonalized': 'Cá nhân hóa voucher này',
  'vouchers.form.description': 'Mô tả',
  'vouchers.form.percent': 'Giảm %',
  'vouchers.form.amount': 'Giảm cố định đ',
  'vouchers.form.minOrder': 'Đơn tối thiểu',
  'vouchers.form.maxDiscount': 'Giảm tối đa',
  'vouchers.form.optional': 'Optional',
  'vouchers.form.customerId': 'Customer ID',
  'vouchers.form.customerUuid': 'Customer UUID',
  'vouchers.form.cancel': 'Hủy',
  'vouchers.form.update': 'Cập nhật',
  'vouchers.form.create': 'Tạo mới',
  'vouchers.card.suspend': 'Tạm ngưng',
  'vouchers.card.activate': 'Kích hoạt',
  'vouchers.card.edit': 'Sửa',
  'vouchers.card.delete': 'Xóa'
};

const keysEn = {
  'vouchers.title': 'Voucher Management',
  'vouchers.create': 'Create Voucher',
  'vouchers.stats.active': 'Active Vouchers',
  'vouchers.stats.redeemed': 'Total Redeemed',
  'vouchers.stats.discountGiven': 'Total Discount',
  'vouchers.stats.avgDiscount': 'Avg Discount',
  'vouchers.tabs.all': 'All',
  'vouchers.tabs.active': 'Active',
  'vouchers.tabs.expiringSoon': 'Expiring Soon',
  'vouchers.tabs.expired': 'Expired',
  'vouchers.tabs.personalized': 'Personalized',
  'vouchers.search': 'Search vouchers...',
  'vouchers.empty': 'No vouchers found',
  'vouchers.createFirst': 'Create first voucher',
  'vouchers.noExpiry': 'No expiry',
  'vouchers.createVoucher': 'Create Voucher',
  'vouchers.form.code': 'Voucher Code',
  'vouchers.form.type': 'Discount Type',
  'vouchers.form.validFrom': 'Valid From',
  'vouchers.form.validUntil': 'Valid Until',
  'vouchers.form.maxUses': 'Max Uses',
  'vouchers.form.usageLimitPerCustomer': 'Limit per Customer',
  'vouchers.form.isPersonalized': 'Personalize this voucher',
  'vouchers.form.description': 'Description',
  'vouchers.form.percent': 'Percent %',
  'vouchers.form.amount': 'Fixed Amount',
  'vouchers.form.minOrder': 'Min Order Value',
  'vouchers.form.maxDiscount': 'Max Discount',
  'vouchers.form.optional': 'Optional',
  'vouchers.form.customerId': 'Customer ID',
  'vouchers.form.customerUuid': 'Customer UUID',
  'vouchers.form.cancel': 'Cancel',
  'vouchers.form.update': 'Update',
  'vouchers.form.create': 'Create',
  'vouchers.card.suspend': 'Suspend',
  'vouchers.card.activate': 'Activate',
  'vouchers.card.edit': 'Edit',
  'vouchers.card.delete': 'Delete'
};

const keysJa = {
  'vouchers.title': 'バウチャー管理',
  'vouchers.create': 'バウチャー作成',
  'vouchers.stats.active': '有効なバウチャー',
  'vouchers.stats.redeemed': '利用回数',
  'vouchers.stats.discountGiven': '割引総額',
  'vouchers.stats.avgDiscount': '平均割引',
  'vouchers.tabs.all': 'すべて',
  'vouchers.tabs.active': '有効',
  'vouchers.tabs.expiringSoon': 'もうすぐ期限切れ',
  'vouchers.tabs.expired': '期限切れ',
  'vouchers.tabs.personalized': 'パーソナライズ',
  'vouchers.search': 'バウチャーを検索...',
  'vouchers.empty': 'バウチャーがありません',
  'vouchers.createFirst': '最初のバウチャーを作成',
  'vouchers.noExpiry': '無期限',
  'vouchers.createVoucher': 'バウチャーを作成',
  'vouchers.form.code': 'バウチャーコード',
  'vouchers.form.type': '割引タイプ',
  'vouchers.form.validFrom': '有効開始日',
  'vouchers.form.validUntil': '有効終了日',
  'vouchers.form.maxUses': '最大利用回数',
  'vouchers.form.usageLimitPerCustomer': '顧客ごとの制限',
  'vouchers.form.isPersonalized': 'このバウチャーをパーソナライズする',
  'vouchers.form.description': '説明',
  'vouchers.form.percent': 'パーセント %',
  'vouchers.form.amount': '固定額',
  'vouchers.form.minOrder': '最低注文金額',
  'vouchers.form.maxDiscount': '最大割引額',
  'vouchers.form.optional': 'オプション',
  'vouchers.form.customerId': '顧客 ID',
  'vouchers.form.customerUuid': '顧客 UUID',
  'vouchers.form.cancel': 'キャンセル',
  'vouchers.form.update': '更新',
  'vouchers.form.create': '作成',
  'vouchers.card.suspend': '一時停止',
  'vouchers.card.activate': '有効化',
  'vouchers.card.edit': '編集',
  'vouchers.card.delete': '削除'
};

addKeys('C:/Users/Per/Downloads/noMoreF2TECH/src/locales/vi.ts', keysVi);
addKeys('C:/Users/Per/Downloads/noMoreF2TECH/src/locales/en.ts', keysEn);
addKeys('C:/Users/Per/Downloads/noMoreF2TECH/src/locales/ja.ts', keysJa);

console.log('Added voucher keys to locales');
