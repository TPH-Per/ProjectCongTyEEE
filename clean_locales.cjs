const fs = require('fs');
const path = require('path');

const localesDir = 'src/locales';
const files = ['vi.ts', 'en.ts', 'ja.ts'];

const missingVi = {
  'auto_title_fix': 'Sửa',
  'auto_placeholder_fix_1': 'Nhập...',
  'auto_placeholder_fix_2': 'Nhập...',
  'auto_placeholder_fix_3': 'Nhập...',
  'auto_placeholder_fix_4': 'Nhập...',
  'auto_an_mat_khau': 'Ẩn mật khẩu',
  'auto_hien_mat_khau': 'Hiện mật khẩu',
  'auto_b_n__ang_ph_c_v_': 'Bàn đang phục vụ'
};

const missingEn = {
  'auto_title_fix': 'Edit',
  'auto_placeholder_fix_1': 'Enter...',
  'auto_placeholder_fix_2': 'Enter...',
  'auto_placeholder_fix_3': 'Enter...',
  'auto_placeholder_fix_4': 'Enter...',
  'auto_an_mat_khau': 'Hide password',
  'auto_hien_mat_khau': 'Show password',
  'auto_b_n__ang_ph_c_v_': 'Table is active'
};

const missingJa = {
  'auto_title_fix': '編集',
  'auto_placeholder_fix_1': '入力...',
  'auto_placeholder_fix_2': '入力...',
  'auto_placeholder_fix_3': '入力...',
  'auto_placeholder_fix_4': '入力...',
  'auto_an_mat_khau': 'パスワードを隠す',
  'auto_hien_mat_khau': 'パスワードを表示',
  'auto_b_n__ang_ph_c_v_': 'テーブル使用中'
};

const missingObj = {
  'vi.ts': missingVi,
  'en.ts': missingEn,
  'ja.ts': missingJa
};

files.forEach(file => {
  const p = path.join(localesDir, file);
  let content = fs.readFileSync(p, 'utf8');
  
  // Clean up auto_t_auto_ lines
  const lines = content.split('\n');
  const newLines = lines.filter(line => !line.includes('auto_t_auto_'));
  
  // Insert missing keys right before the last closing brace
  const lastBraceIdx = newLines.lastIndexOf('}');
  if (lastBraceIdx !== -1) {
    const toInsert = missingObj[file];
    for (const [key, val] of Object.entries(toInsert)) {
      if (!content.includes(`'${key}':`) && !content.includes(`  ${key}:`)) {
         newLines.splice(lastBraceIdx, 0, `  '${key}': '${val}',`);
      }
    }
  }
  
  fs.writeFileSync(p, newLines.join('\n'));
});
console.log('Locales cleaned and missing keys added.');
