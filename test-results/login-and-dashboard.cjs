const { chromium } = require('playwright');
(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1920, height: 1080 } });

  // Go to login page
  await page.goto('http://localhost:5173/login');
  await page.waitForTimeout(2000);

  // Fill login form
  await page.locator('input[type="text"]').fill('admin');
  await page.locator('input[type="password"]').fill('admin123');
  await page.locator('button:has-text("Sign in")').click();
  
  await page.waitForTimeout(5000);
  
  // Check current URL
  console.log('URL after login: ' + page.url());
  
  // Take screenshot
  await page.screenshot({ path: 'test-results/after-login.png' });
  
  // If on branch selection, try to select a branch
  if (page.url().includes('select-branch') || page.url().includes('select_branch')) {
    console.log('On branch selection page');
    const branchButtons = await page.locator('.branch-card, button').all();
    console.log('Found ' + branchButtons.length + ' buttons');
    if (branchButtons.length > 0) {
      await branchButtons[0].click();
      await page.waitForTimeout(3000);
      console.log('After branch select URL: ' + page.url());
    }
  }
  
  // Try navigating to dashboard
  await page.goto('http://localhost:5173/reception/dashboard');
  await page.waitForTimeout(5000);
  console.log('Dashboard URL: ' + page.url());
  
  await page.screenshot({ path: 'test-results/dashboard-final.png', fullPage: true });
  console.log('Screenshot saved');
  
  // Also capture console errors
  page.on('console', msg => console.log('CONSOLE:', msg.text()));

  await browser.close();
})();
