import fs from 'fs';

const missingKeys = JSON.parse(fs.readFileSync('missing_reception_keys.json', 'utf-8'));
const storeContent = fs.readFileSync('src/stores/useLanguageStore.ts', 'utf-8');

const generateText = (key, lang) => {
  const parts = key.split('.');
  const lastPart = parts[parts.length - 1];
  let text = lastPart.replace(/_/g, ' ');
  
  if (lang === 'en') {
    return text.charAt(0).toUpperCase() + text.slice(1);
  }
  
  if (lang === 'ja') {
    if (text.includes('title')) return 'タイトル';
    if (text.includes('checkout')) return 'チェックアウト';
    if (text.includes('close shift')) return 'シフト終了';
    if (text.includes('order')) return '注文';
    if (text.includes('table')) return 'テーブル';
    if (text.includes('no items')) return 'アイテムなし';
    if (text.includes('total')) return '合計';
    return text.charAt(0).toUpperCase() + text.slice(1);
  }
  
  const dict = {
    'title': 'Tiêu đề',
    'checkout': 'Thanh toán',
    'close shift': 'Đóng ca',
    'order': 'Gọi món',
    'table': 'Bàn',
    'no items': 'Không có món',
    'total': 'Tổng cộng',
    'guest': 'Khách',
    'amount': 'Số tiền',
    'price': 'Giá',
    'quantity': 'Số lượng',
    'name': 'Tên',
    'phone': 'Số điện thoại',
    'search': 'Tìm kiếm',
    'member': 'Thành viên',
    'apply': 'Áp dụng',
    'vat': 'VAT',
    'change': 'Tiền thừa',
    'cash': 'Tiền mặt',
    'revenue': 'Doanh thu',
    'history': 'Lịch sử',
    'error': 'Lỗi',
    'loading': 'Đang tải'
  };
  
  let lowerText = text.toLowerCase();
  for (const [k, v] of Object.entries(dict)) {
    if (lowerText.includes(k)) {
      text = text.replace(new RegExp(k, 'i'), v);
    }
  }
  return text.charAt(0).toUpperCase() + text.slice(1);
}

const newVi = [];
const newEn = [];
const newJa = [];

for (const key of missingKeys) {
  const viText = generateText(key, 'vi');
  const enText = generateText(key, 'en');
  const jaText = generateText(key, 'ja');
  
  newVi.push(`    '${key}': '${viText}',`);
  newEn.push(`    '${key}': '${enText}',`);
  newJa.push(`    '${key}': '${jaText}',`);
}

let newContent = storeContent.replace(
  /vi:\s*{([\s\S]*?)},\s*en:/,
  (match, p1) => `vi: {${p1}\n    // Reception Keys\n${newVi.join('\n')}\n  },\n  en:`
);

newContent = newContent.replace(
  /en:\s*{([\s\S]*?)},\s*ja:/,
  (match, p1) => `en: {${p1}\n    // Reception Keys\n${newEn.join('\n')}\n  },\n  ja:`
);

newContent = newContent.replace(
  /ja:\s*{([\s\S]*?)}\s*};/,
  (match, p1) => `ja: {${p1}\n    // Reception Keys\n${newJa.join('\n')}\n  }\n};`
);

fs.writeFileSync('src/stores/useLanguageStore.ts', newContent);
console.log('Patched useLanguageStore.ts with 328 keys');
