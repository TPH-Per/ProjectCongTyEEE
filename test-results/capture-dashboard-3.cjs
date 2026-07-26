const { chromium } = require('playwright');
(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1920, height: 1080 } });

  await page.addInitScript(() => {
    localStorage.setItem('ngu-cat.selectedBranch', 'branch-001');
    localStorage.setItem('ngu-cat.locale', 'vi');
  });

  await page.goto('http://localhost:5173/login');
  await page.waitForTimeout(2000);
  await page.locator('input[type="text"]').fill('admin');
  await page.locator('input[type="password"]').fill('admin123');
  await page.locator('button:has-text("Sign in")').click();
  await page.waitForTimeout(3000);

  await page.goto('http://localhost:5173/reception/dashboard');
  await page.waitForTimeout(5000);

  // Capture viewport only (what user sees without scrolling)
  await page.screenshot({ path: 'test-results/dashboard-viewport.png', fullPage: false });
  
  // Capture full page
  await page.screenshot({ path: 'test-results/dashboard-fullpage.png', fullPage: true });
  
  // Get page dimensions
  const dimensions = await page.evaluate(() => {
    return {
      scrollWidth: document.documentElement.scrollWidth,
      scrollHeight: document.documentElement.scrollHeight,
      clientWidth: document.documentElement.clientWidth,
      clientHeight: document.documentElement.clientHeight,
      bodyScrollHeight: document.body.scrollHeight,
    };
  });
  console.log('Page dimensions:', JSON.stringify(dimensions));
  
  // Check for layout issues
  const issues = await page.evaluate(() => {
    const issues = [];
    
    // Check for elements with overflow
    const allElements = document.querySelectorAll('*');
    for (const el of allElements) {
      const rect = el.getBoundingClientRect();
      if (rect.width > window.innerWidth + 10) {
        issues.push({
          type: 'overflow-x',
          tag: el.tagName,
          class: el.className?.toString?.()?.substring(0, 80),
          width: rect.width,
        });
      }
    }
    
    // Check for large empty spaces
    const mainContent = document.querySelector('.min-h-screen, [class*="bg-[#FAF3E8]"]');
    if (mainContent) {
      const rect = mainContent.getBoundingClientRect();
      issues.push({
        type: 'main-content',
        rect: { top: rect.top, height: rect.height, bottom: rect.bottom }
      });
    }
    
    return issues.slice(0, 20);
  });
  console.log('Layout issues:', JSON.stringify(issues, null, 2));

  await browser.close();
})();
