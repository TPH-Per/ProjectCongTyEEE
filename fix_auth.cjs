const fs = require('fs');

let f1 = fs.readFileSync('src/composables/useAuth.ts', 'utf8');
f1 = f1.replace(/'admin'/g, "'superadmin'");
f1 = f1.replace(/'procurement'/g, "'procurement_manager'"); // fallback
f1 = f1.replace(/'accounting'/g, "'accountant'");
fs.writeFileSync('src/composables/useAuth.ts', f1);

let f2 = fs.readFileSync('src/composables/useReport.ts', 'utf8');
f2 = f2.replace(/'admin'/g, "'superadmin'");
fs.writeFileSync('src/composables/useReport.ts', f2);
