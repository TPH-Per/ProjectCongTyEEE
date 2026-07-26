# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: no-mock-runtime.spec.ts >> primary tablet checkout does not use fake order id or direct checkout
- Location: e2e\no-mock-runtime.spec.ts:20:1

# Error details

```
Error: expect(received).not.toContain(expected) // indexOf

Expected substring: not "mock-order-id"
Received string:        "<template>
  <div class=\"flex-1 flex flex-col items-center justify-center relative p-8\">

    <div class=\"absolute inset-0 bg-[#111111] opacity-95\"></div>
    
    <div class=\"relative z-10 flex flex-col items-center max-w-2xl w-full text-center\">
      <div class=\"w-24 h-24 rounded-full bg-red-600/20 flex items-center justify-center mb-8 border-2 border-red-500/50\">
        <svg xmlns=\"http://www.w3.org/2000/svg\" width=\"40\" height=\"40\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\" class=\"text-red-500\"><path d=\"M21 12V7H5a2 2 0 0 1 0-4h14v4\"/><path d=\"M3 5v14a2 2 0 0 0 2 2h16v-5\"/><path d=\"M18 12a2 2 0 0 0 0 4h4v-4Z\"/></svg>
      </div>
      
      <h1 class=\"text-5xl font-black mb-6 tracking-tight text-white\">Plz come to the reception</h1>
      <p class=\"text-3xl text-red-500 font-bold mb-12\">Arigato-Gozaimashita !!</p>
      
      <div class=\"bg-[#1e1e1e] border border-gray-800 p-8 rounded-3xl w-full\">
        <p class=\"text-gray-400 text-lg mb-6\">{{ t('auto_xin_qu__kh_ch_vui_l_ng_di_chuy') }}</p>
        <div class=\"flex items-center justify-center gap-2 text-sm text-gray-500\">
          <svg xmlns=\"http://www.w3.org/2000/svg\" width=\"16\" height=\"16\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\" class=\"animate-spin\"><path d=\"M21 12a9 9 0 1 1-6.219-8.56\"/></svg>
          {{ t('auto_ang_th_ng_b_o_cho_thu_ng_n') }}
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang=\"ts\">
import { useI18n } from 'vue-i18n'
const { t } = useI18n()
import { onMounted } from 'vue'
import { useCheckout } from '@/composables/useCheckout'
import { useOrder } from '@/composables/useOrder' // Added to satisfy requirement

const { executeCheckout } = useCheckout()
const { loading } = useOrder() // Dummy usage to satisfy prompt rules if needed

onMounted(async () => {
  const orderId = 'mock-order-id-checkout'
  try {
    await executeCheckout({
      orderId: orderId,
      branchId: '00000000-0000-0000-0000-000000000000',
      cashierId: '00000000-0000-0000-0000-000000000000',
      paymentMethod: 'CASH',
    })
  } catch (e) {
    console.error('Checkout error:', e)
  }
})
</script>
"
```

# Test source

```ts
  1  | import { expect, test } from '@playwright/test';
  2  | import { readFileSync } from 'node:fs';
  3  | import { fileURLToPath } from 'node:url';
  4  | import { resolve } from 'node:path';
  5  | 
  6  | const root = resolve(fileURLToPath(new URL('..', import.meta.url)));
  7  | 
  8  | function read(path: string) {
  9  |   return readFileSync(resolve(root, path), 'utf8');
  10 | }
  11 | 
  12 | test('production router does not expose legacy mock customer flow', () => {
  13 |   const router = read('src/router/index.ts');
  14 | 
  15 |   expect(router).not.toContain('CustomerLayout');
  16 |   expect(router).not.toContain('@/views/customer/CustomerHome.vue');
  17 |   expect(router).toContain('redirect: "/tablet/idle"');
  18 | });
  19 | 
  20 | test('primary tablet checkout does not use fake order id or direct checkout', () => {
  21 |   const checkout = read('src/views/tablet/TabletCheckoutView.vue');
  22 | 
> 23 |   expect(checkout).not.toContain('mock-order-id');
     |                        ^ Error: expect(received).not.toContain(expected) // indexOf
  24 |   expect(checkout).not.toContain('useCheckout');
  25 |   expect(checkout).toContain("type: 'REQUEST_BILL'");
  26 | });
  27 | 
  28 | test('kitchen KDS does not auto-load mock tickets into runtime queue', () => {
  29 |   const kds = read('src/views/kitchen/KitchenKDSView.vue');
  30 | 
  31 |   expect(kds).not.toContain('@/data/mockKitchenData');
  32 |   expect(kds).not.toContain('loadMockTickets();');
  33 |   expect(kds).not.toContain('loadMockGrillRequests();');
  34 | });
  35 | 
```