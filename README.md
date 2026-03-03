# AI-Augmented QA Automation --- SauceDemo

**Claude Code + Playwright MCP (Planner / Generator / Healer-ready)**

## Overview

This project demonstrates an AI-augmented QA workflow using:

-   **Playwright Test Agents (Planner / Generator / Healer)**
-   **Claude Code**
-   **SauceDemo** as the system under test

The goal is to show how requirements can be converted into a structured
test plan, automatically generated into a Playwright test suite,
stabilized, and prepared for self-healing workflows.

------------------------------------------------------------------------

# System Under Test

**Application:** https://www.saucedemo.com
**Scope Covered:**

-   Authentication (login / locked-out user)
-   Inventory sorting
-   Cart add/remove behavior
-   Checkout validation
-   Successful end-to-end checkout
-   Negative / edge scenarios (empty cart checkout)

------------------------------------------------------------------------

# Workflow Implemented

## 1️⃣ Planner Agent

Using the Playwright **Planner**, we converted a PRD into a structured,
generator-ready test plan.

Artifacts: - `prd/saucedemo_prd.md` - `test-plans/saucedemo_plan.md`

The plan includes:

-   Scope & assumptions
-   Stable locator strategy
-   Structured test cases (ID, Preconditions, Steps, Assertions,
    Cleanup)
-   Boundary and negative scenarios
-   AI Healer simulation annotation

Total planned test cases: **10**

------------------------------------------------------------------------

## 2️⃣ Generator Agent

The **Generator** converted the test plan into Playwright TypeScript
specs:

    tests/auth.spec.ts
    tests/inventory.spec.ts
    tests/cart.spec.ts
    tests/checkout.spec.ts
    tests/negative.spec.ts

Implementation choices:

-   `getByTestId()` aligned to SauceDemo's `data-test` attributes
-   No brittle CSS or positional selectors
-   Independent tests (no shared state)
-   Event-driven waits (`expect()` used for synchronization)
-   `not.toBeAttached()` for singleton absence checks
-   `toHaveCount(0)` for collection absence checks
-   Trace + screenshot on failure configured

------------------------------------------------------------------------

## 3️⃣ Initial Test Run & Failures

After generation, the first run revealed two key issues.

### Issue #1 --- `getByTestId()` Not Finding Elements

**Problem:**\
Tests failed at login --- Playwright could not find `login-button`.

**Root Cause:**\
SauceDemo uses `data-test`, while Playwright defaults to `data-testid`.

**Fix:**

Configured Playwright to use the correct attribute:

``` ts
// playwright.config.ts
export default defineConfig({
  use: {
    testIdAttribute: 'data-test',
  },
});
```

This aligned locator strategy with the application under test.

------------------------------------------------------------------------

### Issue #2 --- Currency Formatting Assertion Too Strict

**Problem:**\
Test expected:

    Item total: $0.00

Actual rendered value:

    Item total: $0

**Root Cause:**\
Formatting differences between UI totals (`$0` vs `$0.00`).

**Fix:**\
Replaced brittle exact-text assertion with regex:

``` ts
await expect(
  page.getByText(/^\$?Item total: \$0(\.00)?$/)
).toBeVisible();
```

This preserves intent while tolerating formatting variation.

------------------------------------------------------------------------

## 4️⃣ Stable Baseline Achieved

After fixes:

    39 / 39 tests passing

This establishes a stable automation baseline before introducing
simulated drift for Healer validation.

------------------------------------------------------------------------

# Locator Strategy

Priority order:

1.  `getByTestId()` (configured for `data-test`)
2.  `getByRole()` for semantic controls
3.  `getByLabel()` for form fields
4.  `getByText()` for visible assertions only

Forbidden:

-   `nth-child`
-   Deep CSS chains
-   XPath (unless unavoidable)

------------------------------------------------------------------------

# What This Demonstrates

-   Requirements → Structured test plan via AI
-   Plan → Deterministic Playwright suite generation
-   Real-world debugging of:
    -   Locator configuration mismatch
    -   Assertion brittleness
-   Clean, stable, event-driven automation
-   Foundation ready for AI-driven healing workflows

------------------------------------------------------------------------

# Next Steps

-   Simulate selector drift
-   Invoke Playwright Healer agent
-   Capture before/after diff
-   Demonstrate automated maintenance repair
