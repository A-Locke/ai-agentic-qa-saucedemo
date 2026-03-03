// Test Suite: Checkout
// Covers: TC-CHK-001, TC-CHK-002, TC-CHK-003

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

/** Add one item to cart and navigate through to checkout step 1. */
async function goToCheckoutStep1(page: Page, addToCartTestId: string): Promise<void> {
  await page.getByTestId(addToCartTestId).click();
  await page.getByTestId('shopping-cart-link').click();
  await expect(page).toHaveURL(/.*cart\.html/);
  await page.getByTestId('checkout').click();
  await expect(page).toHaveURL(/.*checkout-step-one\.html/);
}

// TC-CHK-001
test('TC-CHK-001: submitting checkout form with all fields empty shows First Name required', async ({ page }) => {
  await loginAsStandardUser(page);
  await goToCheckoutStep1(page, 'add-to-cart-sauce-labs-onesie');

  // Submit without filling any field
  await page.getByTestId('continue').click();

  await expect(page).toHaveURL(/.*checkout-step-one\.html/);
  await expect(page.getByTestId('error')).toBeVisible();
  await expect(page.getByTestId('error')).toContainText('First Name is required');
});

// TC-CHK-002
test('TC-CHK-002: postal code missing shows Postal Code is required error', async ({ page }) => {
  await loginAsStandardUser(page);
  await goToCheckoutStep1(page, 'add-to-cart-sauce-labs-onesie');

  await page.getByTestId('firstName').fill('Jane');
  await page.getByTestId('lastName').fill('Doe');
  // postalCode intentionally left empty
  await page.getByTestId('continue').click();

  await expect(page).toHaveURL(/.*checkout-step-one\.html/);
  await expect(page.getByTestId('error')).toBeVisible();
  await expect(page.getByTestId('error')).toContainText('Postal Code is required');
});

// TC-CHK-003
test('TC-CHK-003: full checkout flow ends on confirmation page', async ({ page }) => {
  await loginAsStandardUser(page);

  await page.getByTestId('add-to-cart-sauce-labs-backpack').click();
  await page.getByTestId('shopping-cart-link').click();
  await expect(page).toHaveURL(/.*cart\.html/);
  await expect(page.getByText('Sauce Labs Backpack')).toBeVisible();

  await page.getByTestId('checkout').click();
  await expect(page).toHaveURL(/.*checkout-step-one\.html/);

  await page.getByTestId('firstName').fill('Jane');
  await page.getByTestId('lastName').fill('Doe');
  await page.getByTestId('postalCode').fill('90210');
  await page.getByTestId('continue').click();

  await expect(page).toHaveURL(/.*checkout-step-two\.html/);
  // Item must appear in the order summary
  await expect(page.getByText('Sauce Labs Backpack')).toBeVisible();

  await page.getByTestId('finish').click();

  await expect(page).toHaveURL(/.*checkout-complete\.html/);
  await expect(page.getByTestId('complete-header')).toBeVisible();
  await expect(page.getByTestId('complete-header')).toHaveText('Thank you for your order!');
  await expect(page.getByTestId('back-to-products')).toBeVisible();
  // Cart is cleared after a completed order
  await expect(page.getByTestId('shopping-cart-badge')).not.toBeAttached();
});
