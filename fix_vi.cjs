const fs = require('fs');
let vi = fs.readFileSync('src/locales/vi.ts', 'utf8');

const additions = `
  'purchasing.receipts.receiveReceiptTitle': 'Tiếp nhận Phiếu giao hàng',
  'purchasing.receipts.scanSubTitle': 'Scan, Paste ảnh (Ctrl+V) hoặc kéo thả hóa đơn để AI tự động điền.',
  'purchasing.receipts.scanImageLabel': 'Ảnh Phiếu Giao',
  'purchasing.receipts.uploadImage': 'Tải ảnh lên',
  'purchasing.receipts.uploadSubText': ', kéo thả, hoặc nhấn Ctrl+V',
  'purchasing.receipts.processingImage': 'Đang xử lý ảnh...',
  'purchasing.receipts.clearImage': 'Xóa ảnh',
  'purchasing.receipts.rotateRight': 'Xoay phải',
  'purchasing.receipts.rotateLeft': 'Xoay trái',
  'purchasing.receipts.receiptDetails': 'Chi tiết Nhập hàng',
  'purchasing.receipts.columns.receiptCode': 'Mã Phiếu Giao',
  'purchasing.receipts.receiptCodePlaceholder': 'VD: GR-2026...',
  'purchasing.receipts.columns.supplier': 'Nhà Cung Cấp',
  'purchasing.receipts.selectSupplier': '-- Chọn Nhà cung cấp --',
  'purchasing.receipts.receiptItems': 'Hàng hóa nhập kho',
  'purchasing.receipts.addRow': 'Thêm dòng',
  'purchasing.receipts.selectIngredient': 'Chọn nguyên liệu',
  'purchasing.receipts.columns.quantity': 'Số lượng',
  'purchasing.receipts.columns.unit': 'Đơn vị tính',
  'purchasing.receipts.columns.totalValue': 'Đơn giá',
  'purchasing.receipts.noItemsAdded': 'Chưa có mặt hàng nào. Bấm "Thêm dòng" để bắt đầu nhập.',
  'purchasing.receipts.totalReceiptValue': 'Tổng Giá Trị Phiếu',
  'purchasing.receipts.saveAndSync': 'Lưu Phiếu & Cập Nhật Tồn Kho',
  'purchasing.receipts.invalidImage': 'Vui lòng chọn file hình ảnh (JPG, PNG).',
  'purchasing.receipts.selectInputTitle': 'Chưa chọn ô nhập',
  'purchasing.receipts.selectInputMsg': 'Vui lòng click vào ô bạn muốn điền dữ liệu (VD: Số lượng, Đơn giá) trước khi click vào chữ trên ảnh.',
  'purchasing.receipts.selectBranchAlert': 'Vui lòng chọn chi nhánh trước khi làm việc.',
  'purchasing.receipts.successAlert': 'Nhập hàng thành công! Tồn kho đã được cập nhật.',
  'purchasing.receipts.errorAlert': 'Lỗi: ',
`;

vi = vi.replace(/}(\s*)$/, additions + '}$1');
fs.writeFileSync('src/locales/vi.ts', vi);
console.log('Fixed vi.ts');
