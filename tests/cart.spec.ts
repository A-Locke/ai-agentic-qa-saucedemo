// Test Suite: Cart
// Covers: TC-CART-001

import { test, expect, type Page } from '@playwright/test';

test.use({
  screenshot: 'only-on-failure',
  trace: 'on-first-retry',
});

async function loginAsStandardUser(page: Page): Promise<void> {
  await page.goto('https://www.saucedemo.com/');
  await page.getByTestId('username').fill('standard_user');
  await page.getByTestId('password').fill('secret_sauce');
  await page.getByTestId('login-button').click();
  await expect(page).toHaveURL(/.*inventory\.html/);
}

// TC-CART-001
test('TC-CART-001: removing the only item in cart clears the badge', async ({ page }) => {
  await loginAsStandardUser(page);

  await page.getByTestId('add-to-cart-sauce-labs-bike-light').click();
  await expect(page.getByTestId('shopping-cart-badge')).toHaveText('1');

  await page.getByTestId('remove-sauce-labs-bike-light').click();

  // Badge disappears entirely — it is absent from DOM, not showing "0"
  await expect(page.getByTestId('shopping-cart-badge')).not.toBeAttached();
  // Add to cart button is restored, confirming the item was fully removed
  await expect(page.getByTestId('add-to-cart-sauce-labs-bike-light')).toBeVisible();
});
