const fs = require('fs');
const path = require('path');

function findVietnameseStrings(dir, results = []) {
  const files = fs.readdirSync(dir);
  for (const file of files) {
    const fullPath = path.join(dir, file);
    if (fs.statSync(fullPath).isDirectory()) {
      findVietnameseStrings(fullPath, results);
    } else if (fullPath.endsWith('.vue') || fullPath.endsWith('.ts')) {
      const content = fs.readFileSync(fullPath, 'utf8');
      // Regex to find Vietnamese characters inside quotes
      const vnRegex = /['"`]([^'"`]*[áàảãạăắằẳẵặâấầẩẫậéèẻẽẹêếềểễệíìỉĩịóòỏõọôốồổỗộơớờởỡợúùủũụưứừửữựýỳỷỹỵđÁÀẢÃẠĂẮẰẲẴẶÂẤẦẨẪẬÉÈẺẼẸÊẾỀỂỄỆÍÌỈĨỊÓÒỎÕỌÔỐỒỔỖỘƠỚỜỞỠỢÚÙỦŨỤƯỨỪỬỮỰÝỲỶỸỴĐ][^'"`]*)['"`]/g;
      
      let match;
      while ((match = vnRegex.exec(content)) !== null) {
        // Exclude some false positives or already translated keys if needed
        if (!match[1].startsWith('auto_')) {
          results.push({ file: fullPath, text: match[1], fullMatch: match[0] });
        }
      }
    }
  }
  return results;
}

const strings = findVietnameseStrings('src/views/admin');
const uniqueStrings = [...new Set(strings.map(s => s.text))];
console.log(`Found ${uniqueStrings.length} unique Vietnamese strings in admin views.`);
console.log(uniqueStrings);

// Also check layouts
const layoutStrings = findVietnameseStrings('src/layouts');
const uniqueLayouts = [...new Set(layoutStrings.map(s => s.text))];
console.log(`Found ${uniqueLayouts.length} unique Vietnamese strings in layouts.`);
console.log(uniqueLayouts);
