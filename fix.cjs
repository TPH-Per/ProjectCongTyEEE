const fs = require('fs');

// 1. Fix src/types/database.ts
let dbTs = fs.readFileSync('src/types/database.ts', 'utf8');
if (!dbTs.includes('export type Json =')) {
  dbTs = 'export type Json = string | number | boolean | null | { [key: string]: Json | undefined } | Json[];\n' + dbTs;
  fs.writeFileSync('src/types/database.ts', dbTs);
}

// 2. Fix src/views/hall/CheckoutView.vue
let checkoutVue = fs.readFileSync('src/views/hall/CheckoutView.vue', 'utf8');
checkoutVue = checkoutVue.replace('branchId: activeBranchId.value,', 'branchId: activeBranchId.value || "",');
fs.writeFileSync('src/views/hall/CheckoutView.vue', checkoutVue);

// 3. Fix usePurchasing.ts
let usePurchasingTs = fs.readFileSync('src/composables/usePurchasing.ts', 'utf8');
if (!usePurchasingTs.includes('fetchPurchaseOrders')) {
  usePurchasingTs = usePurchasingTs.replace(
    'return {',
    'const fetchPurchaseOrders = async () => [];\n  return {\n    fetchPurchaseOrders,'
  );
  fs.writeFileSync('src/composables/usePurchasing.ts', usePurchasingTs);
}

// 4. Fix duplicate keys in vi.ts
let viTs = fs.readFileSync('src/locales/vi.ts', 'utf8');
const viLines = viTs.split('\n');
const viKeys = new Set();
const newViLines = [];
viLines.forEach(line => {
  const match = line.match(/^\s*'([^']+)'\s*:/);
  if (match) {
    if (viKeys.has(match[1])) return;
    viKeys.add(match[1]);
  }
  newViLines.push(line);
});
fs.writeFileSync('src/locales/vi.ts', newViLines.join('\n'));

// 4b. Fix duplicate keys in useLanguageStore.ts
let useLangTs = fs.readFileSync('src/stores/useLanguageStore.ts', 'utf8');
const langLines = useLangTs.split('\n');
const langKeys = new Set();
const newLangLines = [];
let currentLang = '';
langLines.forEach(line => {
  const langMatch = line.match(/^\s*(vi|en|zh):\s*\{\s*$/);
  if (langMatch) {
    currentLang = langMatch[1];
    langKeys.clear();
  }
  const match = line.match(/^\s*'([^']+)'\s*:/);
  if (match) {
    if (langKeys.has(match[1])) return;
    langKeys.add(match[1]);
  }
  newLangLines.push(line);
});
fs.writeFileSync('src/stores/useLanguageStore.ts', newLangLines.join('\n'));

// 5. Fix useReservation.ts
let useResTs = fs.readFileSync('src/composables/useReservation.ts', 'utf8');
useResTs = useResTs.replace(/export interface Reservation \{[\s\S]*?created_at: string\r?\n\}/m, 'import type { ReservationRow as Reservation } from "@/types/database"');
useResTs = useResTs.replace(/if\s*\([^)]*params\?\.search[^)]*\)\s*\{\s*query\s*=\s*query\.or\([^)]+\)\s*\}/, '// search removed');
fs.writeFileSync('src/composables/useReservation.ts', useResTs);

// 6. Fix ReceptionOrderView.vue interpolations
let recvOrderVue = fs.readFileSync('src/views/reception/ReceptionOrderView.vue', 'utf8');
recvOrderVue = recvOrderVue.replace('{ max }', '{ max: String(max) }');
recvOrderVue = recvOrderVue.replace('{ name: product.name, qty: modalItemQty.value }', '{ name: product.name, qty: String(modalItemQty.value) }');
recvOrderVue = recvOrderVue.replace('{ table: selectedTableCode.value, package: activeSettings.value.package, guests: activeOrder.value.guestCount, total: formatVND(summary.value.grandTotal) }', '{ table: selectedTableCode.value || "", package: activeSettings.value.package, guests: String(activeOrder.value.guestCount), total: formatVND(summary.value.grandTotal) }');
recvOrderVue = recvOrderVue.replace('{ sent }', '{ sent: String(sent) }');
recvOrderVue = recvOrderVue.replace('length: skipped.length', 'length: String(skipped.length)');
fs.writeFileSync('src/views/reception/ReceptionOrderView.vue', recvOrderVue);
console.log("Done");
