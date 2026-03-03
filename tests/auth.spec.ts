// Test Suite: Authentication
// Covers: TC-AUTH-001, TC-AUTH-002

import { test, expect, type Page } from '@playwright/test';

test.use({
  screenshot: 'only-on-failure',
  trace: 'on-first-retry',
});

// TC-AUTH-001
test('TC-AUTH-001: standard_user login navigates to inventory page', async ({ page }) => {
  await page.goto('https://www.saucedemo.com/');
  await expect(page.getByTestId('login-button')).toBeVisible();

  await page.getByTestId('username').fill('standard_user');
  await page.getByTestId('password').fill('secret_sauce');
  await page.getByTestId('login-button').click();

  await expect(page).toHaveURL(/.*inventory\.html/);
  await expect(page.getByText('Products')).toBeVisible();
  await expect(page.getByTestId('error')).not.toBeAttached();
});

// TC-AUTH-002
test('TC-AUTH-002: locked_out_user sees locked-out error banner', async ({ page }) => {
  await page.goto('https://www.saucedemo.com/');
  await expect(page.getByTestId('login-button')).toBeVisible();

  await page.getByTestId('username').fill('locked_out_user');
  await page.getByTestId('password').fill('secret_sauce');
  await page.getByTestId('login-button').click();

  await expect(page).not.toHaveURL(/inventory\.html/);
  await expect(page.getByTestId('error')).toBeVisible();
  await expect(page.getByTestId('error')).toContainText(/locked out/i);
  // Cart link is only rendered after a successful login
  await expect(page.getByTestId('shopping-cart-link')).not.toBeAttached();
});
