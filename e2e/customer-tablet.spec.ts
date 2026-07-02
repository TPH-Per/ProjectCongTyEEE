import { test } from '@playwright/test';

test.describe('Customer tablet business flow', () => {
  test.skip('Reservation seated table can open tablet menu with real DB data', async () => {
    // Requires seeded authenticated tablet context and table/session ids.
  });

  test.skip('Customer can add menu item to cart and submit order without duplicate', async () => {
    // Requires seeded branch/table/menu/order data and authenticated tablet context.
  });

  test.skip('Customer can create service request and checkout request', async () => {
    // Requires active tablet session and Hall request queue validation.
  });
});
