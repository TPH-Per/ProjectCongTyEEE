const fs = require('fs');
const layouts = [
  'AdminLayout.vue',
  'DashboardLayout.vue',
  'KitchenLayout.vue',
  'ManagerLayout.vue',
  'ReceptionLayout.vue',
  'StaffLayout.vue',
  'SuperadminLayout.vue'
];
layouts.forEach(file => {
  let p = 'src/layouts/' + file;
  if (!fs.existsSync(p)) return;
  let c = fs.readFileSync(p, 'utf8');
  
  // Remove the old injection
  c = c.replace(/\s*<!-- Header User Avatar -->\s*<div class="flex items-center gap-2 ml-4">\s*<LanguageSwitcher \/>\s*<img :src="stickerUrl" alt="User Avatar" class="w-8 h-8 rounded-full border border-\[hsl\(var\(--border\)\)\] object-contain bg-\[hsl\(var\(--muted\)\)\]" \/>\s*<\/div>/g, '');
  
  // Inject inside the right-side flex div
  c = c.replace(/<\/div>\s*<\/header>/g, '\n        <div class="flex items-center gap-2 ml-4 border-l pl-4 border-[hsl(var(--border))]">\n          <LanguageSwitcher />\n          <img :src="stickerUrl" alt="User Avatar" class="w-8 h-8 rounded-full border border-[hsl(var(--border))] object-contain bg-[hsl(var(--muted))]" />\n        </div>\n      </div>\n      </header>');
  
  fs.writeFileSync(p, c);
  console.log('Fixed flex layout in', file);
});
