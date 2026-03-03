# SauceDemo PRD (Portfolio)

## Goal
Validate core shopper flow: login → browse inventory → add to cart → checkout → confirmation.

## Personas / accounts
- standard_user (happy path)
- locked_out_user (negative path)

## Core requirements
R1. Valid users can log in and reach inventory.
R2. Users can sort products (price low→high).
R3. Users can add/remove items; cart badge updates.
R4. Checkout requires first name, last name, postal code.
R5. Successful checkout shows confirmation.

## Non-functional
NF1. Tests must be deterministic and assert visible evidence (URL, headings, confirmation text).
NF2. Capture traces/screenshots on failure.