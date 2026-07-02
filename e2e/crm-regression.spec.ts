import { test } from '@playwright/test';

test.describe('CRM regression', () => {
  test.skip('CRM survey stays attached to current order/session and links to bill', async () => {
    // Requires seeded active order/table and authenticated CRM user.
  });
});
