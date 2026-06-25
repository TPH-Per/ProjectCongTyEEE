const fs = require('fs');

const layouts = [
  'src/layouts/AdminLayout.vue',
  'src/layouts/ManagerLayout.vue',
  'src/layouts/StaffLayout.vue',
  'src/layouts/ReceptionLayout.vue'
];

for (const file of layouts) {
  if (!fs.existsSync(file)) continue;
  let code = fs.readFileSync(file, 'utf8');

  if (!code.includes('isMobileMenuOpen')) {
    code = code.replace(/<script setup[^>]*>/, match => match + '\nconst isMobileMenuOpen = ref(false)\n');
  }

  if (!code.includes('isMobileMenuOpen = false')) {
    code = code.replace(/<aside\b[^>]*class="([^"]+)"[^>]*>/, (match, classes) => {
      let newClasses = classes.replace(/\b(w-\d+|fixed|relative|inset-y-0|left-0|z-\d+|transform|transition-transform|duration-\d+|md:translate-x-0|-translate-x-full|lg:relative|lg:translate-x-0)\b/g, '').trim();
      return '<div v-if="isMobileMenuOpen" class="fixed inset-0 bg-black/50 z-40 lg:hidden" @click="isMobileMenuOpen = false"></div>\n    <aside :class="[\'' + newClasses + ' w-64 fixed inset-y-0 left-0 z-50 transform transition-transform duration-300 lg:relative lg:translate-x-0\', isMobileMenuOpen ? \'translate-x-0\' : \'-translate-x-full\']">';
    });
  }

  if (!code.includes('isMobileMenuOpen = true')) {
    code = code.replace(/<header\b[^>]*>([\s\S]*?)<h2/, (match, content) => {
      return match.replace(content, content + '<button @click="isMobileMenuOpen = true" class="lg:hidden mr-3 p-2 rounded-lg hover:bg-gray-100"><svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="3" y1="12" x2="21" y2="12"/><line x1="3" y1="6" x2="21" y2="6"/><line x1="3" y1="18" x2="21" y2="18"/></svg></button>\n          ');
    });
  }

  fs.writeFileSync(file, code);
  console.log('Updated ' + file);
}
