const { chromium } = require('playwright');
(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1920, height: 1080 } });

  // Set branch ID in localStorage before navigating
  await page.addInitScript(() => {
    localStorage.setItem('ngu-cat.selectedBranch', 'branch-001');
    localStorage.setItem('ngu-cat.locale', 'vi');
  });

  await page.goto('http://localhost:5173/login');
  await page.waitForTimeout(2000);
  await page.locator('input[type="text"]').fill('admin');
  await page.locator('input[type="password"]').fill('admin123');
  await page.locator('button:has-text("Sign in")').click();
  await page.waitForTimeout(5000);
  
  // Navigate directly to dashboard
  await page.goto('http://localhost:5173/reception/dashboard');
  await page.waitForTimeout(8000);
  
  console.log('URL: ' + page.url());
  const text = await page.locator('body').innerText();
  console.log('Visible text (first 2000 chars):');
  console.log(text.substring(0, 2000));
  
  await page.screenshot({ path: 'test-results/dashboard-actual.png', fullPage: true });
  console.log('Screenshot saved');
  
  await browser.close();
})();
