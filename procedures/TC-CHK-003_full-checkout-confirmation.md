# TC-CHK-003 — Full Checkout: End-to-End Confirmation

| Field | Value |
|---|---|
| **Test ID** | TC-CHK-003 |
| **Suite** | Checkout |
| **Title** | Complete checkout flow ends at confirmation page with order acknowledgement |
| **Type** | Positive (Critical Happy Path) |

---

## Objective

Verify the full purchase flow: add Sauce Labs Backpack → view cart → fill checkout info → review order summary → finish → confirmation page reads "Thank you for your order!" and the cart badge is cleared.

---

## Preconditions

- Fresh browser context — cart empty at start.
- Credentials: `standard_user` / `secret_sauce`.
- Test dataset `valid_checkout`: First Name `Jane`, Last Name `Doe`, Postal Code `90210`.
- Item to purchase: Sauce Labs Backpack.

---

## Session Name

```
tc-chk-003-full-checkout-confirm
```

---

## Steps

Run each command in the same shell session so variables persist. See `scripts/tc-chk-003.sh` for the executable version.

```bash
# 1. Open browser and navigate to the login page
playwright-cli -s=tc-chk-003-full-checkout-confirm open https://www.saucedemo.com/

# 2. Start tracing
playwright-cli -s=tc-chk-003-full-checkout-confirm tracing-start

# 3. Snapshot — S1: login page
playwright-cli -s=tc-chk-003-full-checkout-confirm snapshot --filename=tc-chk-003-s1-login.yaml
# Extract refs:
USERNAME_REF=$(grep 'textbox "Username"' tc-chk-003-s1-login.yaml | grep -o 'ref=e[0-9]*' | cut -d= -f2)
PASSWORD_REF=$(grep 'textbox "Password"' tc-chk-003-s1-login.yaml | grep -o 'ref=e[0-9]*' | cut -d= -f2)
LOGIN_REF=$(grep    'button "Login"'      tc-chk-003-s1-login.yaml | grep -o 'ref=e[0-9]*' | cut -d= -f2)

# 4. Fill credentials and log in
playwright-cli -s=tc-chk-003-full-checkout-confirm fill "$USERNAME_REF" "standard_user"
playwright-cli -s=tc-chk-003-full-checkout-confirm fill "$PASSWORD_REF" "secret_sauce"
playwright-cli -s=tc-chk-003-full-checkout-confirm click "$LOGIN_REF"

# 5. Snapshot — S2: inventory page
# Check: URL contains "inventory.html"; no cart badge visible
playwright-cli -s=tc-chk-003-full-checkout-confirm snapshot --filename=tc-chk-003-s2-inventory.yaml
grep 'Page URL' tc-chk-003-s2-inventory.yaml
ADD_BACKPACK_REF=$(grep -A5 'Sauce Labs Backpack' tc-chk-003-s2-inventory.yaml | grep 'button "Add to cart"' | grep -o 'ref=e[0-9]*' | cut -d= -f2 | head -1)

# 6. Add Sauce Labs Backpack and go to cart
playwright-cli -s=tc-chk-003-full-checkout-confirm click "$ADD_BACKPACK_REF"
# Note: the cart link is NOT exposed in the accessibility tree — use goto
playwright-cli -s=tc-chk-003-full-checkout-confirm goto https://www.saucedemo.com/cart.html

# 7. Snapshot — S3: cart page
# Check: URL contains "cart.html"; "Sauce Labs Backpack" is listed
playwright-cli -s=tc-chk-003-full-checkout-confirm snapshot --filename=tc-chk-003-s3-cart.yaml
grep 'Page URL'            tc-chk-003-s3-cart.yaml
grep 'Sauce Labs Backpack' tc-chk-003-s3-cart.yaml
CHECKOUT_REF=$(grep 'button "Checkout"' tc-chk-003-s3-cart.yaml | grep -o 'ref=e[0-9]*' | cut -d= -f2)

# 8. Proceed to checkout step one
playwright-cli -s=tc-chk-003-full-checkout-confirm click "$CHECKOUT_REF"

# 9. Snapshot — S4: checkout step one
# Check: URL contains "checkout-step-one.html"
# Note: field label is textbox "Zip/Postal Code" (not just "Postal Code")
playwright-cli -s=tc-chk-003-full-checkout-confirm snapshot --filename=tc-chk-003-s4-step-one.yaml
grep 'Page URL' tc-chk-003-s4-step-one.yaml
FNAME_REF=$(grep   'textbox "First Name"'      tc-chk-003-s4-step-one.yaml | grep -o 'ref=e[0-9]*' | cut -d= -f2)
LNAME_REF=$(grep   'textbox "Last Name"'       tc-chk-003-s4-step-one.yaml | grep -o 'ref=e[0-9]*' | cut -d= -f2)
POSTAL_REF=$(grep  'textbox "Zip/Postal Code"' tc-chk-003-s4-step-one.yaml | grep -o 'ref=e[0-9]*' | cut -d= -f2)
CONTINUE_REF=$(grep 'button "Continue"'        tc-chk-003-s4-step-one.yaml | grep -o 'ref=e[0-9]*' | cut -d= -f2)

# 10. Fill checkout info (dataset: valid_checkout)
playwright-cli -s=tc-chk-003-full-checkout-confirm fill "$FNAME_REF"  "Jane"
playwright-cli -s=tc-chk-003-full-checkout-confirm fill "$LNAME_REF"  "Doe"
playwright-cli -s=tc-chk-003-full-checkout-confirm fill "$POSTAL_REF" "90210"
playwright-cli -s=tc-chk-003-full-checkout-confirm click "$CONTINUE_REF"

# 11. Snapshot — S5: checkout step two (order summary)
# Check: URL contains "checkout-step-two.html"; "Sauce Labs Backpack" visible
playwright-cli -s=tc-chk-003-full-checkout-confirm snapshot --filename=tc-chk-003-s5-step-two.yaml
grep 'Page URL'            tc-chk-003-s5-step-two.yaml
grep 'Sauce Labs Backpack' tc-chk-003-s5-step-two.yaml
FINISH_REF=$(grep 'button "Finish"' tc-chk-003-s5-step-two.yaml | grep -o 'ref=e[0-9]*' | cut -d= -f2)

# 12. Finish the order
playwright-cli -s=tc-chk-003-full-checkout-confirm click "$FINISH_REF"

# 13. Snapshot — S6: confirmation page
# Check: URL contains "checkout-complete.html"
# Confirmation heading: heading "Thank you for your order!" [level=2] [ref=eXX]
# Back button label: button "Back Home" (not "Back to Products")
# No cart badge in header
playwright-cli -s=tc-chk-003-full-checkout-confirm snapshot --filename=tc-chk-003-s6-complete.yaml
grep 'Page URL'              tc-chk-003-s6-complete.yaml
grep 'heading.*Thank you'    tc-chk-003-s6-complete.yaml
grep '"Back Home"'           tc-chk-003-s6-complete.yaml
# Extract confirmation header ref:
COMPLETE_HEADER_REF=$(grep 'heading.*Thank you' tc-chk-003-s6-complete.yaml | grep -o 'ref=e[0-9]*' | cut -d= -f2)

# 14. Read confirmation heading text
playwright-cli -s=tc-chk-003-full-checkout-confirm eval "el => el.textContent" "$COMPLETE_HEADER_REF"

# 15. Capture final screenshot
playwright-cli -s=tc-chk-003-full-checkout-confirm screenshot --filename=tc-chk-003-screenshot.png

# 16. Stop tracing and close
playwright-cli -s=tc-chk-003-full-checkout-confirm tracing-stop
playwright-cli -s=tc-chk-003-full-checkout-confirm close
```

---

## Evidence — Pass Criteria

| # | Signal | Where to Confirm |
|---|---|---|
| 1 | "Sauce Labs Backpack" listed in cart | S3 snapshot: `grep 'Sauce Labs Backpack' tc-chk-003-s3-cart.yaml` returns a match |
| 2 | URL reaches `checkout-step-two.html` | S5 snapshot: `grep 'Page URL' tc-chk-003-s5-step-two.yaml` → `checkout-step-two.html` |
| 3 | Backpack visible in order summary | S5 snapshot: `grep 'Sauce Labs Backpack' tc-chk-003-s5-step-two.yaml` returns a match |
| 4 | URL reaches `checkout-complete.html` | S6 snapshot: `grep 'Page URL' tc-chk-003-s6-complete.yaml` → `checkout-complete.html` |
| 5 | Confirmation heading text correct | `eval` on `$COMPLETE_HEADER_REF` returns `Thank you for your order!` |
| 6 | "Back Home" button visible | S6 snapshot: `grep '"Back Home"' tc-chk-003-s6-complete.yaml` returns a match |
| 7 | Cart badge **gone** after order | S6 snapshot first 15 lines: `head -15 tc-chk-003-s6-complete.yaml \| grep 'generic.*"[0-9]"'` — no output |
| 8 | Screenshot shows confirmation page | Screenshot shows the complete page with thank-you heading |

---

## Failure Handling

| Symptom | Action |
|---|---|
| Backpack not listed in cart at S3 | Add-to-cart click did not register. Check S2 badge visibility. Screenshot → stop → restart session |
| Validation error at step one | Re-snapshot S4. `grep 'heading.*Error' tc-chk-003-s4-step-one.yaml` to read error text. Confirm field values in snapshot. Fix fill and retry |
| URL stuck at `checkout-step-two.html` after Finish | Re-snapshot. If Finish button still present: re-click `$FINISH_REF` once. If still stuck: screenshot → stop → report |
| Confirmation heading text differs | `eval` exact text. Screenshot → stop → report as copy regression |
| Cart badge still visible in S6 | `eval` badge text. Screenshot → stop → report as state-management regression |
