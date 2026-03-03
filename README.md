# AI-Augmented QA Automation --- SauceDemo

**Claude Code + Playwright MCP (Planner / Generator / Healer +
CLI-ready)**

------------------------------------------------------------------------

## Overview

This project demonstrates an AI-augmented QA workflow using:

-   **Playwright Test Agents (Planner / Generator / Healer)**
-   **Claude Code**
-   **SauceDemo** as the system under test

The objective is to show how requirements can be transformed into a
structured test plan, automatically generated into a deterministic
Playwright suite, stabilized through debugging, and extended toward
self-healing and CLI-driven execution workflows.

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

The Playwright **Planner** converted a PRD into a structured,
generator-ready test plan.

Artifacts:

-   `prd/saucedemo_prd.md`
-   `test-plans/saucedemo_plan.md`

The plan includes:

-   Scope & assumptions
-   Stable locator strategy
-   Structured test cases (ID, Preconditions, Steps, Assertions,
    Cleanup)
-   Boundary and negative scenarios
-   AI Healer simulation annotation

**Total planned test cases: 10**

------------------------------------------------------------------------

## 2️⃣ Generator Agent

The **Generator** transformed the plan into Playwright TypeScript specs:

    tests/auth.spec.ts
    tests/inventory.spec.ts
    tests/cart.spec.ts
    tests/checkout.spec.ts
    tests/negative.spec.ts

Implementation decisions:

-   `getByTestId()` aligned to SauceDemo's `data-test` attributes
-   No brittle CSS or positional selectors
-   Independent tests (no shared browser state)
-   Event-driven synchronization (`expect()` instead of sleeps)
-   `not.toBeAttached()` for singleton absence checks
-   `toHaveCount(0)` for collection absence checks
-   Trace + screenshot on failure enabled

------------------------------------------------------------------------

## 3️⃣ Initial Test Run & Debugging

The first generated run surfaced two real-world issues.

### Issue #1 --- `getByTestId()` Could Not Find Elements

**Problem:**\
Login tests failed --- Playwright could not locate `login-button`.

**Root Cause:**\
SauceDemo uses `data-test`, while Playwright defaults to `data-testid`.

**Resolution:**

``` ts
// playwright.config.ts
export default defineConfig({
  use: {
    testIdAttribute: 'data-test',
  },
});
```

This aligned the locator strategy with the application under test.

------------------------------------------------------------------------

### Issue #2 --- Currency Formatting Assertion Too Strict

**Problem:**\
The test expected:

    Item total: $0.00

But the UI rendered:

    Item total: $0

**Root Cause:**\
Formatting differences in currency display (`$0` vs `$0.00`).

**Resolution:**\
Replaced brittle exact-text assertion with a resilient regex:

``` ts
await expect(
  page.getByText(/^\$?Item total: \$0(\.00)?$/)
).toBeVisible();
```

This preserves validation intent while tolerating formatting variance.

------------------------------------------------------------------------

## 4️⃣ Stable Baseline Achieved

After fixes:

    39 / 39 tests passing

This commit establishes the stable automation baseline on `main`.

------------------------------------------------------------------------

## 5️⃣ Healer Demonstration (Branch-Based)

A simulated selector drift scenario was introduced and repaired using
the Playwright **Healer** agent.

Branch:

    demo/healer-selector-drift

This branch contains:

-   An intentional locator break
-   A failing test state
-   An AI-assisted repair commit
-   Restored green execution

This demonstrates automated maintenance in response to UI drift while
keeping `main` stable.

------------------------------------------------------------------------

# Locator Strategy

Priority order:

1.  `getByTestId()` (configured for `data-test`)
2.  `getByRole()` for semantic controls
3.  `getByLabel()` for form inputs
4.  `getByText()` for assertion-only evidence

Design principles:

-   No positional selectors (`nth-child`)
-   No brittle CSS chains
-   No XPath unless unavoidable
-   Event-driven waits (`expect`) over time-based sleeps
-   Assertions validate user-visible evidence (URL, headings, banner
    text, badge counts)

------------------------------------------------------------------------

# What This Demonstrates

-   PRD → structured test plan via AI
-   Plan → deterministic Playwright suite generation
-   Real-world debugging:
    -   Test ID configuration mismatch
    -   Assertion brittleness
-   Clean, maintainable locator strategy
-   Simulated UI drift + automated repair
-   Version-controlled agentic QA workflow

------------------------------------------------------------------------

# Upcoming Phase: CLI Skill Playbooks

The next phase extends beyond generated test code.

Planned enhancements:

-   Convert passing Playwright specs into **Playwright CLI skill
    procedures**
-   Create `procedures/*.md` playbooks for agent-driven execution
-   Capture CLI transcripts, snapshots, and trace artifacts
-   Demonstrate deterministic browser control via predefined CLI skills

This layer will showcase:

-   Agent-operable automation workflows
-   Reproducible browser sessions
-   Structured procedural execution
-   Integration of planning, generation, healing, and runtime execution

------------------------------------------------------------------------
