const fs = require('fs');

const additionsEn = `
  'purchasing.receipts.receiveReceiptTitle': 'Receive Goods Receipt',
  'purchasing.receipts.scanSubTitle': 'Scan, Paste image (Ctrl+V) or drag and drop invoice for AI to auto-fill.',
  'purchasing.receipts.scanImageLabel': 'Receipt Image',
  'purchasing.receipts.uploadImage': 'Upload image',
  'purchasing.receipts.uploadSubText': ', drag and drop, or press Ctrl+V',
  'purchasing.receipts.processingImage': 'Processing image...',
  'purchasing.receipts.clearImage': 'Clear image',
  'purchasing.receipts.rotateRight': 'Rotate right',
  'purchasing.receipts.rotateLeft': 'Rotate left',
  'purchasing.receipts.receiptDetails': 'Receipt Details',
  'purchasing.receipts.columns.receiptCode': 'Receipt Code',
  'purchasing.receipts.receiptCodePlaceholder': 'Ex: GR-2026...',
  'purchasing.receipts.columns.supplier': 'Supplier',
  'purchasing.receipts.selectSupplier': '-- Select Supplier --',
  'purchasing.receipts.receiptItems': 'Receipt Items',
  'purchasing.receipts.addRow': 'Add row',
  'purchasing.receipts.selectIngredient': 'Select ingredient',
  'purchasing.receipts.columns.quantity': 'Quantity',
  'purchasing.receipts.columns.unit': 'Unit',
  'purchasing.receipts.columns.totalValue': 'Unit Price',
  'purchasing.receipts.noItemsAdded': 'No items added. Click "Add row" to start.',
  'purchasing.receipts.totalReceiptValue': 'Total Receipt Value',
  'purchasing.receipts.saveAndSync': 'Save Receipt & Update Inventory',
  'purchasing.receipts.invalidImage': 'Please select an image file (JPG, PNG).',
  'purchasing.receipts.selectInputTitle': 'Input not selected',
  'purchasing.receipts.selectInputMsg': 'Please click an input field (e.g. Quantity, Unit Price) before clicking text on the image.',
  'purchasing.receipts.selectBranchAlert': 'Please select a branch before working.',
  'purchasing.receipts.successAlert': 'Receipt submitted successfully! Inventory updated.',
  'purchasing.receipts.errorAlert': 'Error: ',
`;

let en = fs.readFileSync('src/locales/en.ts', 'utf8');
en = en.replace(/}(\s*)$/, additionsEn + '}$1');
fs.writeFileSync('src/locales/en.ts', en);

const additionsJa = `
  'purchasing.receipts.receiveReceiptTitle': '入庫伝票の受領',
  'purchasing.receipts.scanSubTitle': 'スキャン、画像の貼り付け（Ctrl+V）、または請求書をドラッグ＆ドロップしてAIに自動入力させます。',
  'purchasing.receipts.scanImageLabel': '伝票画像',
  'purchasing.receipts.uploadImage': '画像をアップロード',
  'purchasing.receipts.uploadSubText': '、ドラッグ＆ドロップ、またはCtrl+Vを押す',
  'purchasing.receipts.processingImage': '画像を処理中...',
  'purchasing.receipts.clearImage': '画像をクリア',
  'purchasing.receipts.rotateRight': '右に回転',
  'purchasing.receipts.rotateLeft': '左に回転',
  'purchasing.receipts.receiptDetails': '入庫詳細',
  'purchasing.receipts.columns.receiptCode': '伝票コード',
  'purchasing.receipts.receiptCodePlaceholder': '例: GR-2026...',
  'purchasing.receipts.columns.supplier': 'サプライヤー',
  'purchasing.receipts.selectSupplier': '-- サプライヤーを選択 --',
  'purchasing.receipts.receiptItems': '入庫品目',
  'purchasing.receipts.addRow': '行を追加',
  'purchasing.receipts.selectIngredient': '材料を選択',
  'purchasing.receipts.columns.quantity': '数量',
  'purchasing.receipts.columns.unit': '単位',
  'purchasing.receipts.columns.totalValue': '単価',
  'purchasing.receipts.noItemsAdded': '品目がありません。「行を追加」をクリックして開始してください。',
  'purchasing.receipts.totalReceiptValue': '伝票合計額',
  'purchasing.receipts.saveAndSync': '伝票を保存して在庫を更新',
  'purchasing.receipts.invalidImage': '画像ファイル（JPG、PNG）を選択してください。',
  'purchasing.receipts.selectInputTitle': '入力項目が選択されていません',
  'purchasing.receipts.selectInputMsg': '画像上のテキストをクリックする前に、入力フィールド（数量、単価など）をクリックしてください。',
  'purchasing.receipts.selectBranchAlert': '作業前に支店を選択してください。',
  'purchasing.receipts.successAlert': '入庫伝票の保存と在庫更新が完了しました。',
  'purchasing.receipts.errorAlert': 'エラー: ',
`;

let ja = fs.readFileSync('src/locales/ja.ts', 'utf8');
ja = ja.replace(/}(\s*)$/, additionsJa + '}$1');
fs.writeFileSync('src/locales/ja.ts', ja);

console.log('Fixed en.ts and ja.ts');
