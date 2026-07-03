import { expect, test } from '@playwright/test';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { resolve } from 'node:path';

const root = resolve(fileURLToPath(new URL('..', import.meta.url)));

function read(path: string) {
  return readFileSync(resolve(root, path), 'utf8');
}

test('production router does not expose legacy mock customer flow', () => {
  const router = read('src/router/index.ts');

  expect(router).not.toContain('CustomerLayout');
  expect(router).not.toContain('@/views/customer/CustomerHome.vue');
  expect(router).toContain('redirect: "/tablet/idle"');
});

test('primary tablet checkout does not use fake order id or direct checkout', () => {
  const checkout = read('src/views/tablet/TabletCheckoutView.vue');

  expect(checkout).not.toContain('mock-order-id');
  expect(checkout).not.toContain('useCheckout');
  expect(checkout).toContain("type: 'REQUEST_BILL'");
});

test('kitchen KDS does not auto-load mock tickets into runtime queue', () => {
  const kds = read('src/views/kitchen/KitchenKDSView.vue');

  expect(kds).not.toContain('@/data/mockKitchenData');
  expect(kds).not.toContain('loadMockTickets();');
  expect(kds).not.toContain('loadMockGrillRequests();');
});
