# TC-NEG-001 — Edge Case: Checkout with Empty Cart

| Field | Value |
|---|---|
| **Test ID** | TC-NEG-001 |
| **Suite** | Negative / Edge |
| **Title** | Proceeding through checkout with no items results in empty order summary |
| **Type** | Edge Case |

---

## Objective

Verify that a user can navigate through checkout without adding any items: the cart page shows zero items, the order summary on step-two shows zero items, the item total reads "Item total: $0.00", and the "Finish" button is still available (the app does not block $0 orders — documented expected behaviour).

---

## Preconditions

- Fresh browser context — no items added, cart badge not visible at login.
- Credentials: `standard_user` / `secret_sauce`.
- Test dataset `valid_checkout`: First Name `Jane`, Last Name `Doe`, Postal Code `90210`.

---

## Session Name

```
tc-neg-001-empty-cart-checkout
```

---

## Steps

Run each command in the same shell session so variables persist. See `scripts/tc-neg-001.sh` for the executable version.

```bash
# 1. Open browser and navigate to the login page
playwright-cli -s=tc-neg-001-empty-cart-checkout open https://www.saucedemo.com/

# 2. Start tracing
playwright-cli -s=tc-neg-001-empty-cart-checkout tracing-start

# 3. Snapshot — S1: login page
playwright-cli -s=tc-neg-001-empty-cart-checkout snapshot --filename=tc-neg-001-s1-login.yaml
# Extract refs:
USERNAME_REF=$(grep 'textbox "Username"' tc-neg-001-s1-login.yaml | grep -o 'ref=e[0-9]*' | cut -d= -f2)
PASSWORD_REF=$(grep 'textbox "Password"' tc-neg-001-s1-login.yaml | grep -o 'ref=e[0-9]*' | cut -d= -f2)
LOGIN_REF=$(grep    'button "Login"'      tc-neg-001-s1-login.yaml | grep -o 'ref=e[0-9]*' | cut -d= -f2)

# 4. Fill credentials and log in
playwright-cli -s=tc-neg-001-empty-cart-checkout fill "$USERNAME_REF" "standard_user"
playwright-cli -s=tc-neg-001-empty-cart-checkout fill "$PASSWORD_REF" "secret_sauce"
playwright-cli -s=tc-neg-001-empty-cart-checkout click "$LOGIN_REF"

# 5. Snapshot — S2: inventory page — confirm cart is empty
# Check: URL contains "inventory.html"; no cart badge in header (first ~15 lines)
# Do NOT click any "Add to cart" button.
playwright-cli -s=tc-neg-001-empty-cart-checkout snapshot --filename=tc-neg-001-s2-inventory.yaml
grep 'Page URL' tc-neg-001-s2-inventory.yaml
head -15 tc-neg-001-s2-inventory.yaml | grep 'generic.*"[0-9]"'
# (no output = cart is empty = PASS)

# 6. Navigate directly to cart (without adding any item)
# Note: the cart link is NOT exposed in the accessibility tree when empty — use goto
playwright-cli -s=tc-neg-001-empty-cart-checkout goto https://www.saucedemo.com/cart.html

# 7. Snapshot — S3: cart page (empty)
# Check: URL contains "cart.html"; no item rows (no "button Remove" present)
playwright-cli -s=tc-neg-001-empty-cart-checkout snapshot --filename=tc-neg-001-s3-cart.yaml
grep 'Page URL' tc-neg-001-s3-cart.yaml
grep 'button "Remove"' tc-neg-001-s3-cart.yaml
# (no output = no item rows = PASS)
CHECKOUT_REF=$(grep 'button "Checkout"' tc-neg-001-s3-cart.yaml | grep -o 'ref=e[0-9]*' | cut -d= -f2)

# 8. Proceed to checkout step one
playwright-cli -s=tc-neg-001-empty-cart-checkout click "$CHECKOUT_REF"

# 9. Snapshot — S4: checkout step one
# Check: URL contains "checkout-step-one.html"
# Note: field label is textbox "Zip/Postal Code" (not just "Postal Code")
playwright-cli -s=tc-neg-001-empty-cart-checkout snapshot --filename=tc-neg-001-s4-step-one.yaml
grep 'Page URL' tc-neg-001-s4-step-one.yaml
FNAME_REF=$(grep   'textbox "First Name"'      tc-neg-001-s4-step-one.yaml | grep -o 'ref=e[0-9]*' | cut -d= -f2)
LNAME_REF=$(grep   'textbox "Last Name"'       tc-neg-001-s4-step-one.yaml | grep -o 'ref=e[0-9]*' | cut -d= -f2)
POSTAL_REF=$(grep  'textbox "Zip/Postal Code"' tc-neg-001-s4-step-one.yaml | grep -o 'ref=e[0-9]*' | cut -d= -f2)
CONTINUE_REF=$(grep 'button "Continue"'        tc-neg-001-s4-step-one.yaml | grep -o 'ref=e[0-9]*' | cut -d= -f2)

# 10. Fill checkout info and continue
playwright-cli -s=tc-neg-001-empty-cart-checkout fill "$FNAME_REF"  "Jane"
playwright-cli -s=tc-neg-001-empty-cart-checkout fill "$LNAME_REF"  "Doe"
playwright-cli -s=tc-neg-001-empty-cart-checkout fill "$POSTAL_REF" "90210"
playwright-cli -s=tc-neg-001-empty-cart-checkout click "$CONTINUE_REF"

# 11. Snapshot — S5: checkout step two (order summary, empty)
# Check: URL contains "checkout-step-two.html"; no item rows; item total reads $0.00; Finish button present
# Item total appears as: generic [ref=eXX]: "Item total: $0.00"
playwright-cli -s=tc-neg-001-empty-cart-checkout snapshot --filename=tc-neg-001-s5-step-two.yaml
grep 'Page URL'       tc-neg-001-s5-step-two.yaml
grep 'button "Remove"' tc-neg-001-s5-step-two.yaml
# (no output = no item rows = PASS)
grep '"Item total:' tc-neg-001-s5-step-two.yaml
grep 'button "Finish"' tc-neg-001-s5-step-two.yaml
# Extract refs:
ITEM_TOTAL_REF=$(grep '"Item total:' tc-neg-001-s5-step-two.yaml | grep -o 'ref=e[0-9]*' | cut -d= -f2)

# 12. Read item total text to confirm value
playwright-cli -s=tc-neg-001-empty-cart-checkout eval "el => el.textContent" "$ITEM_TOTAL_REF"

# 13. Capture final screenshot
playwright-cli -s=tc-neg-001-empty-cart-checkout screenshot --filename=tc-neg-001-screenshot.png

# 14. Stop tracing and close
playwright-cli -s=tc-neg-001-empty-cart-checkout tracing-stop
playwright-cli -s=tc-neg-001-empty-cart-checkout close
```

---

## Evidence — Pass Criteria

| # | Signal | Where to Confirm |
|---|---|---|
| 1 | Cart badge not visible in S2 | S2 snapshot first 15 lines: `head -15 tc-neg-001-s2-inventory.yaml \| grep 'generic.*"[0-9]"'` — no output |
| 2 | No item rows in cart at S3 | S3 snapshot: `grep 'button "Remove"' tc-neg-001-s3-cart.yaml` — no output |
| 3 | URL reaches `checkout-step-two.html` | S5 snapshot: `grep 'Page URL' tc-neg-001-s5-step-two.yaml` → `checkout-step-two.html` |
| 4 | No item rows in order summary at S5 | S5 snapshot: `grep 'button "Remove"' tc-neg-001-s5-step-two.yaml` — no output |
| 5 | Item total reads `$0.00` | `eval` on `$ITEM_TOTAL_REF` returns `Item total: $0.00` |
| 6 | "Finish" button visible | S5 snapshot: `grep 'button "Finish"' tc-neg-001-s5-step-two.yaml` returns a match |
| 7 | Screenshot shows empty summary | Screenshot shows step-two with no items and $0.00 total |

---

## Failure Handling

| Symptom | Action |
|---|---|
| Cart badge visible in S2 | Context leaked state. Screenshot → `tracing-stop` → reopen with clean session |
| Item rows present in cart at S3 | State leaked from another session. Same as above |
| Page blocked at step-one with an empty-cart error | App has introduced a guard on empty checkouts. Capture exact error text. Update playbook and flag as PRD change |
| Item total shows non-zero value | Cart held items that were not shown. `eval` exact text. Screenshot → stop → report |
| "Finish" button absent in S5 | App now blocks $0 orders. Capture S5 snapshot. Update assertion per new PRD behaviour |
