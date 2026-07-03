import { test } from '@playwright/test';

test.describe('Checkout boundary', () => {
  test.skip('Checkout summary is calculated from order items and final checkout creates bill/payment', async () => {
    // Requires seeded active order with items, authenticated Hall user, and local DB assertions.
  });

  test.skip('Voucher/discount invalid case is rejected when voucher engine is available', async () => {
    // Voucher permission/rule engine remains partial and must be completed before enabling this test.
  });
});
