const fs = require('fs');

let f1 = fs.readFileSync('supabase/functions/admin-user-manager/index.ts', 'utf8');
f1 = f1.replace(/'admin'/g, "'superadmin'");
f1 = f1.replace(/\[\s*'superadmin',\s*'manager',\s*'reception',\s*'staff',\s*'procurement',\s*'accounting',\s*'customer'\s*\]/g, 
  "['superadmin', 'manager', 'reception', 'staff', 'procurement_manager', 'procurement_staff', 'accountant', 'crm_manager', 'marketing']");
fs.writeFileSync('supabase/functions/admin-user-manager/index.ts', f1);

let f2 = fs.readFileSync('supabase/functions/_shared/auth.ts', 'utf8');
f2 = f2.replace(/'admin'/g, "'superadmin'");
fs.writeFileSync('supabase/functions/_shared/auth.ts', f2);
