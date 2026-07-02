const fs = require('fs');

function keepUpstream(file) {
  let content = fs.readFileSync(file, 'utf8');
  content = content.replace(/<<<<<<< .+\r?\n([\s\S]*?)=======\r?\n([\s\S]*?)>>>>>>> .+(?:\r?\n|$)/g, '$2');
  fs.writeFileSync(file, content);
}

function resolveAuth(file) {
  let content = fs.readFileSync(file, 'utf8');
  content = content.replace(/<<<<<<< .+\r?\n([\s\S]*?)=======\r?\n([\s\S]*?)>>>>>>> .+(?:\r?\n|$)/g, (match, ours, theirs) => {
     return `  if (r === 'superadmin' || r === 'admin') {
    return 'superadmin'
  }
  const validRoles: UserRole[] = [
    'superadmin',
    'manager',
    'reception',
    'staff',
    'kitchen',
    'customer',
    'procurement_manager',
    'procurement_staff',
    'accountant',
    'crm_manager',
    'marketing',
    'bod',
    'tablet'
  ]
  if (validRoles.includes(r as UserRole)) {\n`;
  });
  fs.writeFileSync(file, content);
}

function resolveRouter(file) {
  let content = fs.readFileSync(file, 'utf8');
  let conflictIndex = 0;
  content = content.replace(/<<<<<<< .+\r?\n([\s\S]*?)=======\r?\n([\s\S]*?)>>>>>>> .+(?:\r?\n|$)/g, (match, ours, theirs) => {
    conflictIndex++;
    if (conflictIndex === 1) { // The ROUTE_ROLES conflict
      return `  admin: ['superadmin'],
  manager: ['superadmin', 'manager'],
  reception: ['superadmin', 'manager', 'reception'],
  staff: ['superadmin', 'manager', 'staff'],
  hall: ['superadmin', 'manager', 'reception', 'staff'],
  kitchen: ['superadmin', 'manager', 'kitchen'],
  purchasing: ['superadmin', 'procurement_manager', 'procurement_staff'],
  accounting: ['superadmin', 'accountant'],
  crm: ['superadmin', 'manager', 'crm_manager'],
  marketing: ['superadmin', 'manager', 'marketing'],
  bod: ['superadmin', 'bod'],
  tablet: ['superadmin', 'manager', 'reception', 'staff', 'customer'],
}\n`;
    } else {
      return theirs; // keep upstream logic for the second conflict
    }
  });
  fs.writeFileSync(file, content);
}

keepUpstream('src/composables/useReservation.ts');
keepUpstream('src/views/crm/FeedbackManagerView.vue');
keepUpstream('src/views/reception/ReceptionCheckoutView.vue');
keepUpstream('src/views/reception/ReceptionOrderView.vue');

resolveAuth('src/composables/useAuth.ts');
resolveRouter('src/router/index.ts');

console.log('Conflicts resolved successfully.');
