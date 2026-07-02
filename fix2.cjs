const fs = require('fs');

let useRes = fs.readFileSync('src/composables/useReservation.ts', 'utf8');
useRes = useRes.replace(/status !== 'CONFIRMED'/g, "status !== 'Pending'");
useRes = useRes.replace(/status === 'SEATED'/g, "status === 'Dining'");
useRes = useRes.replace(/'SEATED'/g, "'Dining'");
fs.writeFileSync('src/composables/useReservation.ts', useRes);

let resManVue = fs.readFileSync('src/views/hall/ReservationManagerView.vue', 'utf8');
resManVue = resManVue.replace(/res\.guest_name/g, "(res.customer_snapshot as any)?.name || 'Guest'");
resManVue = resManVue.replace(/res\.guest_count/g, "res.guests");
fs.writeFileSync('src/views/hall/ReservationManagerView.vue', resManVue);

let recCheckVue = fs.readFileSync('src/views/reception/ReceptionCheckoutView.vue', 'utf8');
recCheckVue = recCheckVue.replace('{ points: pointsToRedeem', '{ points: String(pointsToRedeem)');
fs.writeFileSync('src/views/reception/ReceptionCheckoutView.vue', recCheckVue);

let routerIdx = fs.readFileSync('src/router/index.ts', 'utf8');
routerIdx = routerIdx.replace(/"superadmin"/g, "'Superadmin'");
fs.writeFileSync('src/router/index.ts', routerIdx);

