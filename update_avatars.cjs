const fs = require('fs');

const layouts = [
  'src/layouts/ManagerLayout.vue',
  'src/layouts/StaffLayout.vue',
  'src/layouts/ReceptionLayout.vue',
  'src/layouts/AdminLayout.vue'
];

for (const file of layouts) {
  if (!fs.existsSync(file)) continue;
  let code = fs.readFileSync(file, 'utf8');

  // Remove any image with 'logo' in its src
  code = code.replace(/<img[^>]*src="[^"]*logo[^"]*"[^>]*>/ig, '');

  if (file.includes('ManagerLayout')) {
    code = code.replace(/src="https?:\/\/[^"]+"/g, 'src="/images/sticker2.png"');
    code = code.replace(/src="\/images\/avatar[^"]+"/g, 'src="/images/sticker2.png"');
  } else if (file.includes('StaffLayout')) {
    code = code.replace(/src="https?:\/\/[^"]+"/g, 'src="/images/sticker3.png"');
    code = code.replace(/src="\/images\/avatar[^"]+"/g, 'src="/images/sticker3.png"');
  } else if (file.includes('ReceptionLayout')) {
    code = code.replace(/src="https?:\/\/[^"]+"/g, 'src="/images/sticker4.png"');
    code = code.replace(/src="\/images\/avatar[^"]+"/g, 'src="/images/sticker4.png"');
  }

  fs.writeFileSync(file, code);
  console.log('Updated avatar in ' + file);
}
