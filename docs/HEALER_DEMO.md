# Healer Demonstration --- Simulated Selector Drift

Branch: `demo/healer-selector-drift`

------------------------------------------------------------------------

## Objective

Demonstrate how the Playwright **Healer agent** can repair a failing
test caused by realistic UI selector drift, while preserving test intent
and maintaining deterministic behavior.

------------------------------------------------------------------------

## Baseline State

On `main`, all tests were passing:

39 / 39 tests passing

The suite uses:

-   `getByTestId()` aligned to `data-test`
-   Stable locator hierarchy
-   No brittle CSS
-   Event-driven waits (`expect`-based synchronization)
-   Deterministic assertions

------------------------------------------------------------------------

## Simulated Drift Scenario

Test affected:

**TC-AI-001 --- Cart badge shows count 1 after adding one item**

Original locator:

``` ts
page.getByTestId('shopping-cart-badge')
```

### Drift Introduced

We intentionally modified the locator to simulate an application change:

``` ts
page.getByTestId('cart-count')
```

This represents a realistic UI rename:

    data-test="shopping-cart-badge"
    → data-test="cart-count"

------------------------------------------------------------------------

## Failure Observed

The test failed with:

    Error: locator.getByTestId('cart-count')
    Expected: visible
    Error: element(s) not found

The application behavior remained correct.\
The failure was caused purely by locator drift.

------------------------------------------------------------------------

## Healer Invocation

The Playwright Healer agent was invoked with constraints:

-   Minimal code changes
-   No sleeps or timing hacks
-   Preserve assertion intent
-   Prefer stable locators
-   Use in-test annotation as guidance

------------------------------------------------------------------------

## Healer Repair Strategy

Based on the in-test annotation and runtime snapshot, the Healer:

1.  Scoped the assertion to the stable cart container
    (`shopping-cart-link`).
2.  Located the numeric badge text (`"1"`) within that container.
3.  Replaced the brittle `cart-count` locator with a contextual locator.

### Actual Healer Fix Applied

``` ts
await expect(
  page.getByTestId('shopping-cart-link').getByText('1')
).toBeVisible();

await expect(
  page.getByTestId('shopping-cart-link').getByText('1')
).toHaveText('1');
```

This approach:

-   Avoids dependence on a specific badge attribute
-   Anchors to a stable parent container
-   Preserves the original test intent
-   Remains deterministic
-   Improves resilience against future attribute drift

------------------------------------------------------------------------

## Post-Repair Result

After the Healer commit:

-   Test suite returned to green
-   No additional tests were modified
-   No timing hacks were introduced
-   Assertion semantics were preserved

------------------------------------------------------------------------

## Version Control Structure

This branch intentionally contains:

**Commit 1:**\
`demo: simulate locator drift for cart badge (shopping-cart-badge -> cart-count)`

**Commit 2:**\
`healer: recover cart badge assertion using resilient locator fallback`

**Commit 3:**\
`docs: add HEALER_DEMO.md describing drift simulation and repair`

This preserves:

-   A visible break
-   An AI-assisted repair
-   A clean maintenance narrative

The `main` branch remains stable and unaffected.

------------------------------------------------------------------------

## What This Demonstrates

-   AI-assisted test maintenance
-   Deterministic recovery from selector drift
-   Preservation of assertion intent
-   Improved locator resilience through contextual scoping
-   Clean version-controlled experimentation

------------------------------------------------------------------------