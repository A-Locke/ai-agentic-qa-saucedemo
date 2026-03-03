// Test Suite: Negative / Edge
// Covers: TC-NEG-001, TC-AI-001

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

// TC-NEG-001
test('TC-NEG-001: checkout with empty cart shows no items in order summary', async ({ page }) => {
  await loginAsStandardUser(page);

  // Confirm cart is genuinely empty before proceeding
  await expect(page.getByTestId('shopping-cart-badge')).not.toBeAttached();

  await page.getByTestId('shopping-cart-link').click();
  await expect(page).toHaveURL(/.*cart\.html/);
  await expect(page.getByTestId('cart-item')).toHaveCount(0);

  await page.getByTestId('checkout').click();
  await expect(page).toHaveURL(/.*checkout-step-one\.html/);

  await page.getByTestId('firstName').fill('Jane');
  await page.getByTestId('lastName').fill('Doe');
  await page.getByTestId('postalCode').fill('90210');
  await page.getByTestId('continue').click();

  await expect(page).toHaveURL(/.*checkout-step-two\.html/);
  // No cart items in the order summary
  await expect(page.getByTestId('cart-item')).toHaveCount(0);
  // Checkout totals are plain text — no data-test attribute exists on these lines
  await expect(page.getByText(/^Item total: \$0(\.00)?$/)).toBeVisible();
  await expect(page.getByTestId('finish')).toBeVisible();
});

// TC-AI-001 — AI Healer Demo
test('TC-AI-001: [AI Healer Demo] cart badge shows count 1 after adding one item', async ({ page }) => {
  // ═══════════════════════════════════════════════════════════════
  // HEALER ANNOTATION  (advisory — this test is fully deterministic)
  // ───────────────────────────────────────────────────────────────
  // Primary locator under watch:
  //   page.getByTestId('shopping-cart-badge')
  //
  // Simulated break scenario:
  //   The app ships a rename: data-test="shopping-cart-badge" →
  //   data-test="cart-count", or the attribute is removed entirely.
  //   The locators on the final two assertions will throw
  //   "no element found" / "locator resolved to hidden element".
  //
  // Expected healer strategy:
  //   1. Take a fresh accessibility snapshot of the post-add-to-cart
  //      page state.
  //   2. Search the snapshot for a numeric text node ("1") that is a
  //      descendant of the cart icon link:
  //        data-test="shopping-cart-link"  OR
  //        role="link" with accessible name containing "cart".
  //   3. Propose a replacement locator — in priority order:
  //        a. page.getByTestId('shopping-cart-link').getByText('1')
  //        b. page.getByRole('link', { name: /cart/i }).getByText('1')
  //        c. page.getByRole('link', { name: /cart/i })
  //              .locator('[class*="badge"]')
  //   4. Record the drift event in the healer log, apply the
  //      replacement, and let the test continue deterministically.
  //
  // The assertion intent does not change regardless of drift:
  //   the badge visible and its text equals "1".
  // ═══════════════════════════════════════════════════════════════

  await loginAsStandardUser(page);

  // Cart must start empty
  await expect(page.getByTestId('shopping-cart-badge')).not.toBeAttached();

  // This click triggers the badge render — the step where locator drift surfaces
  await page.getByTestId('add-to-cart-sauce-labs-fleece-jacket').click();

  // Intentional drift simulation: assume badge id renamed
  await expect(page.getByTestId('cart-count')).toBeVisible();
  await expect(page.getByTestId('cart-count')).toHaveText('1');

  // Confirm the item's own button flipped to Remove (secondary evidence)
  await expect(page.getByTestId('remove-sauce-labs-fleece-jacket')).toBeVisible();
});
