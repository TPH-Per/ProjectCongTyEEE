const { chromium } = require('playwright');
(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1920, height: 1080 } });

  // Go to login page
  await page.goto('http://localhost:5173/login');
  await page.waitForTimeout(2000);

  // Take screenshot of login page to understand structure
  await page.screenshot({ path: 'test-results/login-page.png' });
  
  // Get all inputs
  const inputs = await page.locator('input').all();
  console.log('Found ' + inputs.length + ' inputs');
  for (let i = 0; i < inputs.length; i++) {
    const type = await inputs[i].getAttribute('type');
    const placeholder = await inputs[i].getAttribute('placeholder');
    console.log('Input ' + i + ': type=' + type + ' placeholder=' + placeholder);
  }
  
  // Get all buttons
  const buttons = await page.locator('button').all();
  console.log('Found ' + buttons.length + ' buttons');
  for (let i = 0; i < buttons.length; i++) {
    const text = await buttons[i].textContent();
    console.log('Button ' + i + ': ' + text);
  }

  await browser.close();
})();
