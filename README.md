# AI-Augmented QA Automation --- SauceDemo

**Claude Code + Playwright MCP (Planner → Generator → Healer →
CLI-ready)**

------------------------------------------------------------------------

## Overview

This project explores an **AI-augmented QA automation workflow** using:

-   **Playwright Test Agents (Planner / Generator / Healer)**
-   **Claude Code**
-   **SauceDemo** as the system under test

The goal is to demonstrate how a **Product Requirements Document (PRD)**
can be transformed into a deterministic Playwright test suite,
stabilized through debugging, and maintained using an AI-assisted
healing workflow.

The project models a full **agentic QA pipeline**:

1.  Requirements → structured test design
2.  Automated test generation
3.  Execution and debugging
4.  Simulated UI drift
5.  AI-assisted test repair

------------------------------------------------------------------------

# Architecture

``` mermaid
flowchart TD
    PRD[Product Requirements Document]
    Planner[Planner Agent]
    Plan[Structured Test Plan]
    Generator[Generator Agent]
    Tests[Playwright Test Suite]
    Execute[Test Execution]
    Failure[Test Failure]
    Healer[Healer Agent]
    Repair[Locator Repair]

    PRD --> Planner
    Planner --> Plan
    Plan --> Generator
    Generator --> Tests
    Tests --> Execute
    Execute --> Failure
    Failure --> Healer
    Healer --> Repair
    Repair --> Tests
```

High-level flow:

PRD → Planner → Test Plan → Generator → Playwright Suite → Execution →
Healer → Repair

------------------------------------------------------------------------

# System Under Test

**Application:**\
https://www.saucedemo.com

### Scope Covered

-   Authentication (login / locked-out user)
-   Inventory sorting
-   Cart add/remove behavior
-   Checkout validation
-   Successful end-to-end checkout
-   Negative / edge scenarios

------------------------------------------------------------------------

# Project Structure

    ai-agentic-qa-saucedemo
    │
    ├── .claude/                 # Claude Code configuration
    ├── .github/                 # Repository and CI configuration
    ├── .vscode/                 # Local workspace settings
    │
    ├── prd/                     # Product Requirements Document
    │   └── saucedemo_prd.md
    │
    ├── test-plans/              # Planner-generated test plan
    │   └── saucedemo_plan.md
    │
    ├── tests/                   # Playwright test suite
    │   ├── auth.spec.ts
    │   ├── cart.spec.ts
    │   ├── checkout.spec.ts
    │   ├── inventory.spec.ts
    │   ├── negative.spec.ts
    │   ├── example.spec.ts
    │   └── seed.spec.ts
    │
    ├── .mcp.json                # Playwright MCP configuration
    ├── playwright.config.ts     # Playwright configuration
    ├── package.json             # Node project configuration
    ├── package-lock.json
    ├── .gitignore
    └── README.md

The structure mirrors a typical QA workflow:

-   requirements
-   test planning
-   test implementation
-   documentation of maintenance experiments

------------------------------------------------------------------------

# Workflow Implemented

## 1️⃣ Planner Agent

The Playwright **Planner** converted a PRD into a structured,
generator-ready test plan.

Artifacts:

    prd/saucedemo_prd.md
    test-plans/saucedemo_plan.md

The generated plan includes:

-   Scope & assumptions
-   Stable locator strategy
-   Structured test cases
-   Preconditions, steps, assertions
-   Boundary and negative scenarios
-   AI Healer simulation annotations

**Total planned test cases:** 10

------------------------------------------------------------------------

## 2️⃣ Generator Agent

The **Generator** transformed the plan into Playwright TypeScript tests:

    tests/auth.spec.ts
    tests/inventory.spec.ts
    tests/cart.spec.ts
    tests/checkout.spec.ts
    tests/negative.spec.ts

Implementation decisions:

-   `getByTestId()` aligned to SauceDemo `data-test` attributes
-   No brittle CSS or positional selectors
-   Independent tests (no shared browser state)
-   Event-driven synchronization (`expect()` instead of sleeps)
-   `not.toBeAttached()` for singleton absence checks
-   `toHaveCount(0)` for collection absence checks
-   Trace + screenshot on failure enabled

The repository also includes:

    tests/seed.spec.ts

which demonstrates the canonical login flow used during planning and
generation.

------------------------------------------------------------------------

# Initial Test Run & Debugging

The first generated run surfaced two realistic automation issues.

------------------------------------------------------------------------

## Issue 1 --- `getByTestId()` Not Finding Elements

**Problem**

Login tests failed --- Playwright could not locate:

    login-button

**Root Cause**

SauceDemo uses:

    data-test

while Playwright defaults to:

    data-testid

**Resolution**

Configured Playwright to use the correct attribute:

``` ts
// playwright.config.ts
export default defineConfig({
  use: {
    testIdAttribute: 'data-test',
  },
});
```

------------------------------------------------------------------------

## Issue 2 --- Currency Assertion Too Strict

**Problem**

Test expected:

    Item total: $0.00

UI rendered:

    Item total: $0

**Root Cause**

Currency formatting variance.

**Resolution**

Replaced brittle assertion with regex:

``` ts
await expect(
  page.getByText(/^\$?Item total: \$0(\.00)?$/)
).toBeVisible();
```

This preserves validation intent while tolerating formatting
differences.

------------------------------------------------------------------------

# Stable Baseline

After fixes:

    39 / 39 tests passing

This establishes the stable automation baseline on the **main** branch.

------------------------------------------------------------------------

# Healer Demonstration

A simulated selector drift scenario was introduced on a separate branch:

    demo/healer-selector-drift

The branch contains:

1.  Intentional locator break\
2.  Failing test execution\
3.  AI-assisted repair commit\
4.  Restored green suite

Example healed locator:

``` ts
await expect(
  page.getByTestId('shopping-cart-link').getByText('1')
).toBeVisible();
```

The fix scopes the assertion to a stable parent container instead of
relying on a fragile attribute.

Full walkthrough available here:

https://github.com/A-Locke/ai-agentic-qa-saucedemo/blob/demo/healer-selector-drift/docs/HEALER_DEMO.md

------------------------------------------------------------------------

# Locator Strategy

Priority order:

1.  `getByTestId()` (configured for `data-test`)
2.  `getByRole()` for semantic controls
3.  `getByLabel()` for form inputs
4.  `getByText()` for assertions

Design rules:

-   Avoid positional selectors (`nth-child`)
-   Avoid deep CSS chains
-   Avoid XPath unless unavoidable
-   Prefer event-driven waits
-   Validate **user-visible behavior**, not DOM structure

------------------------------------------------------------------------

# Running the Tests

Install dependencies

    npm install

Install Playwright browsers

    npx playwright install

Run the test suite

    npx playwright test

View the HTML report

    npx playwright show-report

------------------------------------------------------------------------

# Test Results

Stable baseline:

    39 / 39 tests passing

Playwright report example:

    playwright-report/index.html

------------------------------------------------------------------------

# What This Project Demonstrates

-   AI-assisted test planning
-   Automated Playwright suite generation
-   Debugging real automation issues
-   Resilient locator design
-   Version-controlled drift simulation
-   AI-assisted maintenance workflows

------------------------------------------------------------------------

# Next Phase --- CLI Skill Playbooks

Future work will extend the project by converting tests into
**Playwright CLI skill playbooks**.

Planned additions:

-   `procedures/*.md` browser automation playbooks
-   agent-driven test execution
-   CLI session transcripts
-   snapshot-based element references
-   reproducible browser automation flows

This will demonstrate how AI agents can move from **test generation** to
**runtime browser operation**.

------------------------------------------------------------------------
