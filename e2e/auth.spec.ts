import { test, expect } from '@playwright/test';

test('Login page renders successfully', async ({ page }) => {
  await page.goto('http://localhost:5173/login');
  
  // Expect title to be Ngưu Cát POS
  await expect(page).toHaveTitle(/Ngưu Cát/i);
  
  // Expect email input and password input
  const emailInput = page.locator('input[type="email"]');
  const passwordInput = page.locator('input[type="password"]');
  const submitButton = page.locator('button[type="submit"]');

  await expect(emailInput).toBeVisible();
  await expect(passwordInput).toBeVisible();
  await expect(submitButton).toBeVisible();
});

test('Login fails with invalid credentials', async ({ page }) => {
  await page.goto('http://localhost:5173/login');
  
  await page.fill('input[type="email"]', 'wrong@email.com');
  await page.fill('input[type="password"]', 'wrongpassword');
  await page.click('button[type="submit"]');

  // Should see an error message
  const errorMessage = page.locator('.login-error');
  await expect(errorMessage).toBeVisible({ timeout: 5000 });
});
