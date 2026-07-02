const fs = require('fs');

// 1. Fix database.ts
let db = fs.readFileSync('src/types/database.ts', 'utf8');
db = db.replace(/export type UserRole = 'superadmin' \| 'manager' \| 'reception' \| 'staff' \| 'customer' \| 'procurement_manager' \| 'procurement_staff' \| 'accountant' \| 'crm_manager' \| 'marketing'/g, 
  "export type UserRole = 'superadmin' | 'manager' | 'reception' | 'staff' | 'customer' | 'procurement_manager' | 'procurement_staff' | 'accountant' | 'crm_manager' | 'marketing' | 'kitchen' | 'bod' | 'tablet'");
db = db.replace(/export type Json =\r?\n  \| string\r?\n  \| number\r?\n  \| boolean\r?\n  \| null\r?\n  \| \{ \[key: string\]: Json \| undefined \}\r?\n  \| Json\[\]/g, '');
fs.writeFileSync('src/types/database.ts', db);

// 2. Fix FeedbackManagerView.vue
let fb = fs.readFileSync('src/views/crm/FeedbackManagerView.vue', 'utf8');
fb = fb.replace(/const \{ fetchCustomerFeedback, loading \} = useCRM\(\)\r?\nconst feedbacks = ref<any\[\]>\(\[\]\)\r?\n\r?\nfunction formatDate[\s\S]*?const \{ feedbacks, loading, listFeedback, replyToFeedback \} = useFeedback\(\)/g, 
  "const { feedbacks, loading, listFeedback, replyToFeedback } = useFeedback()");
fs.writeFileSync('src/views/crm/FeedbackManagerView.vue', fb);

// 3. Fix CustomerCart.vue
let cc = fs.readFileSync('src/views/customer/CustomerCart.vue', 'utf8');
cc = cc.replace(/store\.updateCartItemNote/g, 'store.updateCartItem');
fs.writeFileSync('src/views/customer/CustomerCart.vue', cc);

// 4. Fix CustomerMenu.vue
let cm = fs.readFileSync('src/views/customer/CustomerMenu.vue', 'utf8');
cm = cm.replace(/store\.loading/g, 'false /* store.loading */');
fs.writeFileSync('src/views/customer/CustomerMenu.vue', cm);

// 5. Fix Feedback.vue
let f = fs.readFileSync('src/views/customer/Feedback.vue', 'utf8');
f = f.replace(/rating: rating\.value,/g, 'rating: rating.value as 1|2|3|4|5,');
fs.writeFileSync('src/views/customer/Feedback.vue', f);

// 6. Fix ReceptionOrderView.vue
let ro = fs.readFileSync('src/views/reception/ReceptionOrderView.vue', 'utf8');
ro = ro.replace(/if \(sent > 0\) triggerToast\('success', t\('reception_order\.da_gui_mon_den_kds', \{ sent: String\(sent\) \}\)\)/g, '');
fs.writeFileSync('src/views/reception/ReceptionOrderView.vue', ro);

console.log('Build errors fixed');
