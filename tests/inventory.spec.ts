// Test Suite: Inventory
// Covers: TC-INV-001, TC-INV-002

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

// TC-INV-001
test('TC-INV-001: sort Price (low to high) produces correct ascending price order', async ({ page }) => {
  await loginAsStandardUser(page);
  await expect(page.getByText('Products')).toBeVisible();

  await page.getByTestId('product-sort-container').selectOption({ label: 'Price (low to high)' });

  // Wait for list to re-render: cheapest item must be first
  await expect(page.getByTestId('inventory-item-price').first()).toHaveText('$7.99');

  const priceTexts = await page.getByTestId('inventory-item-price').allTextContents();
  const prices = priceTexts.map(t => parseFloat(t.replace('$', '')));

  // Anchor assertions
  expect(prices[0]).toBe(7.99);
  expect(prices[prices.length - 1]).toBe(49.99);

  // Full ascending-order invariant
  for (let i = 1; i < prices.length; i++) {
    expect(prices[i]).toBeGreaterThanOrEqual(prices[i - 1]);
  }
});

// TC-INV-002
test('TC-INV-002: adding one item to cart shows badge count of 1', async ({ page }) => {
  await loginAsStandardUser(page);

  // Cart must start empty — badge is absent, not "0"
  await expect(page.getByTestId('shopping-cart-badge')).not.toBeAttached();

  await page.getByTestId('add-to-cart-sauce-labs-backpack').click();

  await expect(page.getByTestId('shopping-cart-badge')).toBeVisible();
  await expect(page.getByTestId('shopping-cart-badge')).toHaveText('1');
  // Button text flipped to Remove, confirming item is registered in cart
  await expect(page.getByTestId('remove-sauce-labs-backpack')).toBeVisible();
});
