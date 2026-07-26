const { chromium } = require('playwright');
(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1920, height: 1080 } });

  await page.goto('http://localhost:5173/login');
  await page.waitForTimeout(2000);
  await page.locator('input[type="text"]').fill('admin');
  await page.locator('input[type="password"]').fill('admin123');
  await page.locator('button:has-text("Sign in")').click();
  await page.waitForTimeout(8000);
  
  const text = await page.locator('body').innerText();
  console.log('Visible text:');
  console.log(text);
  
  await page.screenshot({ path: 'test-results/select-branch-after-fix.png', fullPage: true });
  console.log('Screenshot saved');
  
  await browser.close();
})();
