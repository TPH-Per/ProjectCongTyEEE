import { test } from '@playwright/test';

test.describe('Hall and reception business flow', () => {
  test.skip('Hall can confirm reservation and seat guest without duplicate session', async () => {
    // Requires seeded reservation and authenticated Hall user.
  });

  test.skip('Hall can receive and resolve tablet service request', async () => {
    // Requires seeded tablet service request and authenticated Hall user.
  });

  test.skip('Hall can see table order created from tablet', async () => {
    // Requires seeded active table order.
  });
});
