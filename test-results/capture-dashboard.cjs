const { chromium } = require('playwright');
(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1920, height: 1080 } });

  await page.goto('http://localhost:5173/login');
  await page.waitForTimeout(2000);

  // Fill login form - try different selectors
  const emailInput = page.locator('input').first();
  await emailInput.fill('admin');
  const pwInput = page.locator('input[type="password"]');
  await pwInput.fill('password');
  await page.locator('button[type="submit"]').click();

  await page.waitForTimeout(3000);

  await page.goto('http://localhost:5173/reception/dashboard');
  await page.waitForTimeout(5000);

  await page.screenshot({ path: 'test-results/dashboard-logged-in.png', fullPage: true });
  console.log('Screenshot saved');

  await browser.close();
})();
