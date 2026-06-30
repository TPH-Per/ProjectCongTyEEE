import fs from 'fs';

const missingKeys = JSON.parse(fs.readFileSync('missing_dashboard_keys.json', 'utf-8'));
const storeContent = fs.readFileSync('src/stores/useLanguageStore.ts', 'utf-8');

const generateText = (key, lang) => {
  const parts = key.split('.');
  const lastPart = parts[parts.length - 1];
  let text = lastPart.replace(/_/g, ' ');
  
  if (lang === 'en') {
    return text.charAt(0).toUpperCase() + text.slice(1);
  }
  
  if (lang === 'ja') {
    if (text.includes('dashboard')) return 'ダッシュボード';
    if (text.includes('overview')) return '概要';
    if (text.includes('today')) return '今日';
    if (text.includes('table')) return 'テーブル';
    if (text.includes('checkout')) return 'チェックアウト';
    if (text.includes('reservation')) return '予約';
    if (text.includes('shift')) return 'シフト';
    if (text.includes('action')) return 'アクション';
    if (text.includes('guest')) return 'ゲスト';
    if (text.includes('code')) return 'コード';
    if (text.includes('time')) return '時間';
    if (text.includes('status')) return 'ステータス';
    if (text.includes('invoice')) return '請求書';
    return text.charAt(0).toUpperCase() + text.slice(1);
  }
  
  const dict = {
    'dashboard': 'Bảng điều khiển',
    'overview': 'Tổng quan',
    'today': 'Hôm nay',
    'table': 'Bàn',
    'checkout': 'Thanh toán',
    'reservation': 'Đặt bàn',
    'shift': 'Ca làm việc',
    'action': 'Hành động',
    'guest': 'Khách',
    'code': 'Mã',
    'time': 'Thời gian',
    'status': 'Trạng thái',
    'invoice': 'Hóa đơn'
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
  (match, p1) => `vi: {${p1}\n    // Dashboard Keys\n${newVi.join('\n')}\n  },\n  en:`
);

newContent = newContent.replace(
  /en:\s*{([\s\S]*?)},\s*ja:/,
  (match, p1) => `en: {${p1}\n    // Dashboard Keys\n${newEn.join('\n')}\n  },\n  ja:`
);

newContent = newContent.replace(
  /ja:\s*{([\s\S]*?)}\s*};/,
  (match, p1) => `ja: {${p1}\n    // Dashboard Keys\n${newJa.join('\n')}\n  }\n};`
);

fs.writeFileSync('src/stores/useLanguageStore.ts', newContent);
console.log('Patched useLanguageStore.ts with 28 keys');
