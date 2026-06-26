const fs = require('fs');

const appendKeys = (file, keys) => {
  let content = fs.readFileSync(file, 'utf8');
  for (const [key, val] of Object.entries(keys)) {
    if (!content.includes(key + ':')) {
      content = content.replace(/(export default \{[\s\S]*?)(\n\})/, `$1,\n  ${key}: '${val}'$2`);
    }
  }
  fs.writeFileSync(file, content, 'utf8');
};

appendKeys('src/locales/en.ts', {
  auto_chi_nhanh_branch: 'Branch',
  auto_chon_chi_nhanh: 'Select Branch'
});

appendKeys('src/locales/ja.ts', {
  auto_chi_nhanh_branch: 'ブランチ (Branch)',
  auto_chon_chi_nhanh: 'ブランチを選択 (Select Branch)'
});

appendKeys('src/locales/vi.ts', {
  auto_chi_nhanh_branch: 'Chi nhánh (Branch)',
  auto_chon_chi_nhanh: 'Chọn chi nhánh'
});

console.log('Translations updated.');
