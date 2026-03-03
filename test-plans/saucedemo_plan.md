# SauceDemo Test Plan

**Version:** 1.0
**Date:** 2026-03-03
**Target:** https://www.saucedemo.com/
**Source PRD:** prd/saucedemo_prd.md
**Seed File:** tests/seed.spec.ts

---

## A) Scope & Assumptions

### In Scope
- Authentication (login / logout)
- Inventory page: product listing, sort functionality
- Cart: add item, remove item, badge counter
- Checkout flow: field validation, successful order completion
- Negative/edge cases: empty cart checkout, locked-out user, missing required fields

### Out of Scope
- Performance benchmarks or load testing
- Visual regression (pixel-level comparisons)
- `problem_user`, `performance_glitch_user`, `error_user`, `visual_user` accounts (not in PRD)
- Payment processing (site uses no real payment gateway)
- Responsive/mobile layout

### Assumptions
1. SauceDemo is a stable public demo app; product names and prices are fixed and deterministic.
2. Each test starts from a fresh browser context (no shared cookies or local storage between tests).
3. The seed login flow (`tests/seed.spec.ts`) is the canonical login helper — tests that need an authenticated state re-use this same pattern inline in their own setup (no shared state across tests).
4. `data-test` attributes on SauceDemo are stable and preferred over CSS selectors.
5. The checkout form accepts any non-empty string values for first name, last name, and postal code.
6. "Cart badge" refers to the numeric counter displayed on the cart icon in the top-right header.
7. When the cart is empty the cart badge is not rendered in the DOM (i.e., it is absent, not showing "0").

---

## B) Test Data

### User Accounts

| Handle | Username | Password | Expected Behavior |
|---|---|---|---|
| standard_user | `standard_user` | `secret_sauce` | Logs in; reaches /inventory.html |
| locked_out_user | `locked_out_user` | `secret_sauce` | Login rejected; error banner shown |

### Checkout Form Data

| Dataset Label | First Name | Last Name | Postal Code |
|---|---|---|---|
| valid_checkout | `Jane` | `Doe` | `90210` |
| missing_firstname | _(empty)_ | `Doe` | `90210` |
| missing_lastname | `Jane` | _(empty)_ | `90210` |
| missing_postal | `Jane` | `Doe` | _(empty)_ |

### Product Reference (used in assertions)

| Product Name (as displayed) | Price | data-test add-to-cart value |
|---|---|---|
| Sauce Labs Onesie | $7.99 | `add-to-cart-sauce-labs-onesie` |
| Sauce Labs Bike Light | $9.99 | `add-to-cart-sauce-labs-bike-light` |
| Sauce Labs Bolt T-Shirt | $15.99 | `add-to-cart-sauce-labs-bolt-t-shirt` |
| Test.allTheThings() T-Shirt (Red) | $15.99 | `add-to-cart-test.allthethings()-t-shirt-(red)` ⚠️ |
| Sauce Labs Backpack | $29.99 | `add-to-cart-sauce-labs-backpack` |
| Sauce Labs Fleece Jacket | $49.99 | `add-to-cart-sauce-labs-fleece-jacket` |

> ⚠️ `Test.allTheThings()` add-to-cart ID contains special characters (`.`, `(`, `)`). Generator should resolve the exact value via a fresh page snapshot rather than hardcoding. This item is only referenced in the sort order list; no test case uses its add-to-cart button directly.

> **Sort order for Price (low to high):** Onesie ($7.99) → Bike Light ($9.99) → Bolt T-Shirt ($15.99) → Test.allTheThings() T-Shirt ($15.99) → Backpack ($29.99) → Fleece Jacket ($49.99).

---

## C) Locator Strategy

### Priority Order
1. **`getByTestId()`** — `data-test` attributes are present throughout SauceDemo and are the most stable target. Always prefer these.
2. **`getByRole()`** — Use for interactive controls that carry accessible roles (buttons, comboboxes, links) when a `data-test` id is not available.
3. **`getByLabel()`** — Use for form fields identified by their label text.
4. **`getByText()`** — Use only for asserting visible static text (headings, confirmation messages). Do **not** use to find clickable controls.

### Forbidden Strategies
- CSS `nth-child` / positional selectors (`div:nth-child(3)`)
- Full CSS chains (`.inventory_list > .inventory_item:first-child .btn`)
- XPath unless there is no other option
- Locators that embed price values (prices could theoretically change in future demos)
- Assumed `data-test` IDs on checkout summary total lines (`subtotal-label`, `tax-label`, `total-label`) — these elements do **not** carry `data-test` attributes on SauceDemo; assert their text content via `getByText()` instead

### Key `data-test` IDs (SauceDemo Reference)

| Element | `data-test` value |
|---|---|
| Username input | `username` |
| Password input | `password` |
| Login button | `login-button` |
| Login error banner | `error` |
| Sort dropdown | `product-sort-container` |
| Cart link (header icon) | `shopping-cart-link` |
| Cart badge (item count) | `shopping-cart-badge` |
| Checkout button (cart page) | `checkout` |
| First name field | `firstName` |
| Last name field | `lastName` |
| Postal code field | `postalCode` |
| Continue button (step 1) | `continue` |
| Finish button (step 2) | `finish` |
| Confirmation header | `complete-header` |
| Back to products button | `back-to-products` |

---

## D) Test Suite Outline

```
Suite 1 – Authentication (Auth)
  TC-AUTH-001  Successful login — standard_user
  TC-AUTH-002  Failed login — locked_out_user error evidence

Suite 2 – Inventory (Inv)
  TC-INV-001   Sort products Price (low to high) — verify ascending order
  TC-INV-002   Add one item — cart badge increments to 1

Suite 3 – Cart (Cart)
  TC-CART-001  Add then remove item — cart badge absent after removal

Suite 4 – Checkout (Chk)
  TC-CHK-001   Validation: submit with all fields empty
  TC-CHK-002   Validation: submit with postal code missing
  TC-CHK-003   Successful end-to-end checkout confirmation

Suite 5 – Negative / Edge (Neg)
  TC-NEG-001   Checkout attempted with empty cart — no items in order summary
  TC-AI-001    [AI Healer Demo] Cart badge locator drift simulation
```

---

## E) Detailed Test Cases

---

### TC-AUTH-001 — Successful login with standard_user

| Field | Detail |
|---|---|
| **ID** | TC-AUTH-001 |
| **Title** | Successful login navigates to inventory page |
| **Purpose / Risk** | Validates R1 (core login path). Risk: regression blocks all downstream tests. |
| **Preconditions** | Fresh browser context. No prior session. Starting URL: `https://www.saucedemo.com/`. |
| **Test Data** | Username: `standard_user` / Password: `secret_sauce` |
| **Cleanup** | None required — browser context is discarded after each test. |

**Steps**

1. Navigate to `https://www.saucedemo.com/`.
2. Wait for the page to reach a stable state: expect the element with `data-test="login-button"` to be visible.
3. Fill `data-test="username"` with `standard_user`.
4. Fill `data-test="password"` with `secret_sauce`.
5. Click `data-test="login-button"`.
6. Wait for navigation to complete.

**Assertions**

- URL matches the pattern `.*inventory\.html`.
- Element with text `Products` is visible (heading on the inventory page).
- Element with `data-test="error"` is **not** present in the DOM (no error shown).

---

### TC-AUTH-002 — Login failure with locked_out_user

| Field | Detail |
|---|---|
| **ID** | TC-AUTH-002 |
| **Title** | Locked-out user sees correct error banner |
| **Purpose / Risk** | Validates locked-out account rejection. Risk: error text mismatch causes silent security bypass in UI. |
| **Preconditions** | Fresh browser context. Starting URL: `https://www.saucedemo.com/`. |
| **Test Data** | Username: `locked_out_user` / Password: `secret_sauce` |
| **Cleanup** | None required. |

**Steps**

1. Navigate to `https://www.saucedemo.com/`.
2. Expect `data-test="login-button"` to be visible.
3. Fill `data-test="username"` with `locked_out_user`.
4. Fill `data-test="password"` with `secret_sauce`.
5. Click `data-test="login-button"`.

**Assertions**

- URL does **not** change to `inventory.html` — URL remains at `https://www.saucedemo.com/` (or `/`).
- Element `data-test="error"` is visible.
- Text content of `data-test="error"` contains the string `locked out` (case-insensitive match acceptable).
- `data-test="shopping-cart-link"` is **not** present (confirms user is not logged in).

---

### TC-INV-001 — Sort products Price (low to high), verify ascending order

| Field | Detail |
|---|---|
| **ID** | TC-INV-001 |
| **Title** | Inventory sort Price (low to high) produces correct ascending price order |
| **Purpose / Risk** | Validates R2 (sort). Risk: sort logic breaks silently; customers see wrong pricing order. |
| **Preconditions** | Logged in as `standard_user`. Current page: `/inventory.html`. |
| **Test Data** | Username: `standard_user` / Password: `secret_sauce`. Expected first product price after sort: `$7.99`. Expected last product price after sort: `$49.99`. |
| **Cleanup** | None required — inventory state resets between test contexts. |

**Steps**

1. Log in as `standard_user` using the seed login flow (navigate → fill credentials → click login → wait for `inventory.html` URL).
2. Expect the text `Products` to be visible (confirms page is fully loaded).
3. Select the option `Price (low to high)` in the dropdown identified by `data-test="product-sort-container"`.
4. Wait for the product list to re-render: expect the first item's price element (first `data-test="inventory-item-price"` in the DOM) to contain `$7.99`.
5. Collect all visible price text values from all elements with `data-test="inventory-item-price"`.

**Assertions**

- The selected option in `data-test="product-sort-container"` equals `Price (low to high)` (or value `lohi`).
- The first rendered price text equals `$7.99`.
- The last rendered price text equals `$49.99`.
- The sequence of price values parsed as floats is in non-decreasing order (i.e., each price ≥ previous price).

---

### TC-INV-002 — Add one item increments cart badge to 1

| Field | Detail |
|---|---|
| **ID** | TC-INV-002 |
| **Title** | Adding one item to cart shows badge count of 1 |
| **Purpose / Risk** | Validates R3 (cart badge). Risk: badge counter mismatch misleads users about cart contents. |
| **Preconditions** | Logged in as `standard_user`. Current page: `/inventory.html`. Cart is empty (fresh context). |
| **Test Data** | Username: `standard_user` / Password: `secret_sauce`. Item to add: `Sauce Labs Backpack` (`data-test="add-to-cart-sauce-labs-backpack"`). |
| **Cleanup** | None — browser context discarded. |

**Steps**

1. Log in as `standard_user` using the seed login flow.
2. Expect `data-test="shopping-cart-badge"` to be **absent** (cart starts empty).
3. Click the button with `data-test="add-to-cart-sauce-labs-backpack"`.
4. Wait for `data-test="shopping-cart-badge"` to become visible.

**Assertions**

- `data-test="shopping-cart-badge"` is visible.
- Text content of `data-test="shopping-cart-badge"` equals `1`.
- The button for `Sauce Labs Backpack` now reads `Remove` (i.e., `data-test="remove-sauce-labs-backpack"` is visible, confirming state change).

---

### TC-CART-001 — Add then remove item clears cart badge

| Field | Detail |
|---|---|
| **ID** | TC-CART-001 |
| **Title** | Removing the only item in cart causes badge to disappear |
| **Purpose / Risk** | Validates R3 (remove from cart). Risk: stale badge count confuses users into thinking items remain. |
| **Preconditions** | Logged in as `standard_user`. Current page: `/inventory.html`. Cart is empty. |
| **Test Data** | Username: `standard_user` / Password: `secret_sauce`. Item: `Sauce Labs Bike Light` (`data-test="add-to-cart-sauce-labs-bike-light"` / `remove-sauce-labs-bike-light`). |
| **Cleanup** | None — browser context discarded. |

**Steps**

1. Log in as `standard_user` using the seed login flow.
2. Click `data-test="add-to-cart-sauce-labs-bike-light"`.
3. Expect `data-test="shopping-cart-badge"` to be visible with text `1`.
4. Click `data-test="remove-sauce-labs-bike-light"` (the Remove button that replaced Add to Cart).
5. Wait for `data-test="shopping-cart-badge"` to be absent.

**Assertions**

- After step 4, `data-test="shopping-cart-badge"` is **not** present in the DOM.
- The `Add to cart` button for `Sauce Labs Bike Light` is visible again (i.e., `data-test="add-to-cart-sauce-labs-bike-light"` is visible), confirming the item was fully removed.

---

### TC-CHK-001 — Checkout step 1: all fields empty shows validation error

| Field | Detail |
|---|---|
| **ID** | TC-CHK-001 |
| **Title** | Submitting checkout info form with all fields empty shows "First Name is required" error |
| **Purpose / Risk** | Validates R4 (required field enforcement). Risk: empty form accepted allows orders with no delivery information. |
| **Preconditions** | Logged in as `standard_user`. One item in cart. Current page: `/checkout-step-one.html`. |
| **Test Data** | Username: `standard_user` / Password: `secret_sauce`. Item added: `Sauce Labs Onesie`. Checkout data: all fields left empty. |
| **Cleanup** | None — browser context discarded. |

**Steps**

1. Log in as `standard_user` using the seed login flow.
2. Click `data-test="add-to-cart-sauce-labs-onesie"`.
3. Click `data-test="shopping-cart-link"` to navigate to the cart page.
4. Expect URL to contain `cart.html`.
5. Click `data-test="checkout"`.
6. Expect URL to contain `checkout-step-one.html`.
7. Leave `data-test="firstName"`, `data-test="lastName"`, and `data-test="postalCode"` all empty.
8. Click `data-test="continue"`.

**Assertions**

- URL remains at `checkout-step-one.html` (no navigation forward).
- `data-test="error"` is visible.
- Text content of `data-test="error"` contains `First Name is required`.

---

### TC-CHK-002 — Checkout step 1: postal code missing shows validation error

| Field | Detail |
|---|---|
| **ID** | TC-CHK-002 |
| **Title** | Submitting checkout info form without postal code shows "Postal Code is required" error |
| **Purpose / Risk** | Validates R4 boundary: first name and last name filled but postal missing. Risk: incomplete address accepted. |
| **Preconditions** | Logged in as `standard_user`. One item in cart. Current page: `/checkout-step-one.html`. |
| **Test Data** | Dataset `missing_postal`: First Name: `Jane`, Last Name: `Doe`, Postal Code: _(empty)_. |
| **Cleanup** | None — browser context discarded. |

**Steps**

1. Log in as `standard_user` using the seed login flow.
2. Click `data-test="add-to-cart-sauce-labs-onesie"`.
3. Click `data-test="shopping-cart-link"`.
4. Expect URL to contain `cart.html`.
5. Click `data-test="checkout"`.
6. Expect URL to contain `checkout-step-one.html`.
7. Fill `data-test="firstName"` with `Jane`.
8. Fill `data-test="lastName"` with `Doe`.
9. Leave `data-test="postalCode"` empty.
10. Click `data-test="continue"`.

**Assertions**

- URL remains at `checkout-step-one.html`.
- `data-test="error"` is visible.
- Text content of `data-test="error"` contains `Postal Code is required`.

---

### TC-CHK-003 — Successful end-to-end checkout shows confirmation

| Field | Detail |
|---|---|
| **ID** | TC-CHK-003 |
| **Title** | Complete checkout flow ends at confirmation page with order acknowledgement |
| **Purpose / Risk** | Validates R5 (confirmation). Critical happy path; risk: checkout silently fails or loops. |
| **Preconditions** | Logged in as `standard_user`. One item in cart. Starting from `/inventory.html`. |
| **Test Data** | Username: `standard_user` / Password: `secret_sauce`. Item: `Sauce Labs Backpack`. Checkout data (dataset `valid_checkout`): First Name: `Jane`, Last Name: `Doe`, Postal Code: `90210`. |
| **Cleanup** | None — browser context discarded. |

**Steps**

1. Log in as `standard_user` using the seed login flow.
2. Click `data-test="add-to-cart-sauce-labs-backpack"`.
3. Click `data-test="shopping-cart-link"`.
4. Expect URL to contain `cart.html`.
5. Expect the item name `Sauce Labs Backpack` to be visible in the cart.
6. Click `data-test="checkout"`.
7. Expect URL to contain `checkout-step-one.html`.
8. Fill `data-test="firstName"` with `Jane`.
9. Fill `data-test="lastName"` with `Doe`.
10. Fill `data-test="postalCode"` with `90210`.
11. Click `data-test="continue"`.
12. Expect URL to contain `checkout-step-two.html`.
13. Expect the item name `Sauce Labs Backpack` to be visible in the order summary.
14. Click `data-test="finish"`.
15. Expect URL to contain `checkout-complete.html`.

**Assertions**

- URL contains `checkout-complete.html`.
- `data-test="complete-header"` is visible.
- Text content of `data-test="complete-header"` equals `Thank you for your order!`.
- `data-test="back-to-products"` is visible (confirming the complete page rendered fully).
- `data-test="shopping-cart-badge"` is **not** present (cart has been cleared after order).

---

### TC-NEG-001 — Checkout with empty cart shows no items in order summary

| Field | Detail |
|---|---|
| **ID** | TC-NEG-001 |
| **Title** | Proceeding through checkout with no items in cart results in empty order summary |
| **Purpose / Risk** | Edge case: user navigates directly to cart and proceeds to checkout without adding any items. Risk: system accepts $0 orders silently; also verifies cart empty state renders correctly. |
| **Preconditions** | Logged in as `standard_user`. Cart is empty (fresh login, no items added). |
| **Test Data** | Username: `standard_user` / Password: `secret_sauce`. Checkout data: First Name: `Jane`, Last Name: `Doe`, Postal Code: `90210`. |
| **Cleanup** | None — browser context discarded. |

**Steps**

1. Log in as `standard_user` using the seed login flow.
2. Expect `data-test="shopping-cart-badge"` to be **absent** (confirms cart is empty before proceeding).
3. Click `data-test="shopping-cart-link"` to navigate to the cart page.
4. Expect URL to contain `cart.html`.
5. Expect that no elements with `data-test="cart-item"` are present in the DOM (empty cart state).
6. Click `data-test="checkout"`.
7. Expect URL to contain `checkout-step-one.html`.
8. Fill `data-test="firstName"` with `Jane`.
9. Fill `data-test="lastName"` with `Doe`.
10. Fill `data-test="postalCode"` with `90210`.
11. Click `data-test="continue"`.
12. Expect URL to contain `checkout-step-two.html`.

**Assertions**

- On the order summary page (`checkout-step-two.html`), no `data-test="cart-item"` elements are present (empty order).
- Element with text matching `Item total: $0.00` is visible (use `getByText('Item total: $0.00')` — the checkout summary totals are rendered as plain text; no `data-test` attribute exists on these lines).
- `data-test="finish"` button is still visible (the application does not block submission — this is the documented behavior; if future PRD changes to block, update assertion to expect an error banner).

---

### TC-AI-001 — [AI Healer Demo] Cart badge locator drift simulation

| Field | Detail |
|---|---|
| **ID** | TC-AI-001 |
| **Title** | Cart badge count is visible and correct after adding one item — with healer annotation for locator drift |
| **Purpose / Risk** | Demonstrates AI Healer value: if `data-test="shopping-cart-badge"` is renamed or removed in a future app version, the healer should detect the broken locator and recover using alternate stable signals. This test is deterministic; the healer annotation is advisory only. |
| **Preconditions** | Logged in as `standard_user`. Cart is empty. Current page: `/inventory.html`. |
| **Test Data** | Username: `standard_user` / Password: `secret_sauce`. Item to add: `Sauce Labs Fleece Jacket` (`data-test="add-to-cart-sauce-labs-fleece-jacket"`). |
| **Cleanup** | None — browser context discarded. |

**Steps**

1. Log in as `standard_user` using the seed login flow.
2. Confirm `data-test="shopping-cart-badge"` is absent (cart empty).
3. Click `data-test="add-to-cart-sauce-labs-fleece-jacket"`.

   > **[Healer Annotation — Step 3]**
   > *Simulated locator break:* Suppose the app ships a change where `data-test="shopping-cart-badge"` is renamed to `data-test="cart-count"` or removed entirely. The generated test's locator `getByTestId('shopping-cart-badge')` will fail with "element not found".
   > *Expected healer strategy:*
   > 1. The healer takes a fresh accessibility snapshot of the current page state.
   > 2. It searches the snapshot for a numeric element (`"1"`) that is a child of, or adjacent to, the cart icon link (`data-test="shopping-cart-link"` or `role="link"` with name containing "cart").
   > 3. It proposes a replacement locator using the nearest stable parent: e.g., `page.getByTestId('shopping-cart-link').getByText('1')` or a role-based fallback `page.getByRole('link', { name: /cart/i }).locator('[class*="badge"]')`.
   > 4. The healer records the proposed locator update in a drift log and applies it — the test then continues deterministically from step 4.
   > *The original assertion still holds: the badge must display `"1"` after adding one item.*

4. Wait for the cart badge element to become visible (using the primary locator `data-test="shopping-cart-badge"`, or the healer-resolved alternate if primary is absent).

**Assertions**

- Cart badge element is visible in the page header.
- Text content of the cart badge equals `1`.
- `data-test="remove-sauce-labs-fleece-jacket"` is visible (confirms item was registered in cart).

---

## Summary Table

| ID | Suite | Title | Type | Covers PRD Req |
|---|---|---|---|---|
| TC-AUTH-001 | Auth | Successful login — standard_user | Positive | R1 |
| TC-AUTH-002 | Auth | Failed login — locked_out_user | Negative | R1 |
| TC-INV-001 | Inventory | Sort Price low→high ascending order | Positive | R2 |
| TC-INV-002 | Inventory | Add item increments badge to 1 | Positive | R3 |
| TC-CART-001 | Cart | Remove item clears cart badge | Positive | R3 |
| TC-CHK-001 | Checkout | All fields empty — validation error | Negative | R4 |
| TC-CHK-002 | Checkout | Missing postal code — validation error | Boundary | R4 |
| TC-CHK-003 | Checkout | Full happy path — confirmation shown | Positive | R4, R5 |
| TC-NEG-001 | Negative | Empty cart checkout — no items in summary | Edge | R3, R4 |
| TC-AI-001 | AI Demo | Cart badge with healer locator drift annotation | AI Demo | R3, NF1 |

**Total: 10 test cases** (within 8–12 target range)
