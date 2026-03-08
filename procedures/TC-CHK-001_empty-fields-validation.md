# TC-CHK-001 — Checkout Validation: All Fields Empty

| Field | Value |
|---|---|
| **Test ID** | TC-CHK-001 |
| **Suite** | Checkout |
| **Title** | Submitting checkout info form with all fields empty shows "First Name is required" |
| **Type** | Negative |

---

## Objective

Verify that clicking "Continue" on the checkout step-one form with all three fields empty blocks forward navigation and displays the error message "First Name is required".

---

## Preconditions

- Fresh browser context.
- Credentials: `standard_user` / `secret_sauce`.
- One item in cart (Sauce Labs Bike Light added during setup).
- Checkout form fields must all be left empty before submit.

---

## Session Name

```
tc-chk-001-empty-fields-validation
```

---

## Steps

Run each command in the same shell session so variables persist. See `scripts/tc-chk-001.sh` for the executable version.

```bash
# 1. Open browser and navigate to the login page
playwright-cli -s=tc-chk-001-empty-fields-validation open https://www.saucedemo.com/

# 2. Start tracing
playwright-cli -s=tc-chk-001-empty-fields-validation tracing-start

# 3. Snapshot — S1: login page
playwright-cli -s=tc-chk-001-empty-fields-validation snapshot --filename=tc-chk-001-s1-login.yaml
# Extract refs:
USERNAME_REF=$(grep 'textbox "Username"' tc-chk-001-s1-login.yaml | grep -o 'ref=e[0-9]*' | cut -d= -f2)
PASSWORD_REF=$(grep 'textbox "Password"' tc-chk-001-s1-login.yaml | grep -o 'ref=e[0-9]*' | cut -d= -f2)
LOGIN_REF=$(grep    'button "Login"'      tc-chk-001-s1-login.yaml | grep -o 'ref=e[0-9]*' | cut -d= -f2)

# 4. Fill credentials and log in
playwright-cli -s=tc-chk-001-empty-fields-validation fill "$USERNAME_REF" "standard_user"
playwright-cli -s=tc-chk-001-empty-fields-validation fill "$PASSWORD_REF" "secret_sauce"
playwright-cli -s=tc-chk-001-empty-fields-validation click "$LOGIN_REF"

# 5. Snapshot — S2: inventory page — add Bike Light for setup
playwright-cli -s=tc-chk-001-empty-fields-validation snapshot --filename=tc-chk-001-s2-inventory.yaml
ADD_BIKE_LIGHT_REF=$(grep -A5 'Sauce Labs Bike Light' tc-chk-001-s2-inventory.yaml | grep 'button "Add to cart"' | grep -o 'ref=e[0-9]*' | cut -d= -f2 | head -1)
playwright-cli -s=tc-chk-001-empty-fields-validation click "$ADD_BIKE_LIGHT_REF"

# 6. Navigate to cart
# Note: the cart link is NOT exposed in the accessibility tree — use goto
playwright-cli -s=tc-chk-001-empty-fields-validation goto https://www.saucedemo.com/cart.html

# 7. Snapshot — S3: cart page
# Check: URL contains "cart.html"; "Sauce Labs Bike Light" is listed
playwright-cli -s=tc-chk-001-empty-fields-validation snapshot --filename=tc-chk-001-s3-cart.yaml
grep 'Page URL' tc-chk-001-s3-cart.yaml
CHECKOUT_REF=$(grep 'button "Checkout"' tc-chk-001-s3-cart.yaml | grep -o 'ref=e[0-9]*' | cut -d= -f2)

# 8. Proceed to checkout step one
playwright-cli -s=tc-chk-001-empty-fields-validation click "$CHECKOUT_REF"

# 9. Snapshot — S4: checkout step one (all fields empty)
# Check: URL contains "checkout-step-one.html"; all three fields visible and empty
# Do NOT fill any field.
playwright-cli -s=tc-chk-001-empty-fields-validation snapshot --filename=tc-chk-001-s4-step-one.yaml
grep 'Page URL' tc-chk-001-s4-step-one.yaml
CONTINUE_REF=$(grep 'button "Continue"' tc-chk-001-s4-step-one.yaml | grep -o 'ref=e[0-9]*' | cut -d= -f2)

# 10. Submit with all fields empty
playwright-cli -s=tc-chk-001-empty-fields-validation click "$CONTINUE_REF"

# 11. Snapshot — S5: post-submit error state
# Check: URL still contains "checkout-step-one.html"
# Error element in accessibility tree:
#   heading "Error: First Name is required" [level=3] [ref=eXX]
playwright-cli -s=tc-chk-001-empty-fields-validation snapshot --filename=tc-chk-001-s5-error.yaml
grep 'Page URL'       tc-chk-001-s5-error.yaml
grep 'heading.*Error' tc-chk-001-s5-error.yaml
# Extract error ref:
ERROR_REF=$(grep 'heading.*Error' tc-chk-001-s5-error.yaml | grep -o 'ref=e[0-9]*' | cut -d= -f2)

# 12. Read error text to confirm exact message
playwright-cli -s=tc-chk-001-empty-fields-validation eval "el => el.textContent" "$ERROR_REF"

# 13. Capture final screenshot
playwright-cli -s=tc-chk-001-empty-fields-validation screenshot --filename=tc-chk-001-screenshot.png

# 14. Stop tracing and close
playwright-cli -s=tc-chk-001-empty-fields-validation tracing-stop
playwright-cli -s=tc-chk-001-empty-fields-validation close
```

---

## Evidence — Pass Criteria

| # | Signal | Where to Confirm |
|---|---|---|
| 1 | URL remains at `checkout-step-one.html` | S5 snapshot: `grep 'Page URL' tc-chk-001-s5-error.yaml` → still contains `checkout-step-one.html` |
| 2 | Error banner visible on page | S5 snapshot: `grep 'heading.*Error' tc-chk-001-s5-error.yaml` returns a match |
| 3 | Error text is "First Name is required" | `eval` on `$ERROR_REF` returns `Error: First Name is required` |
| 4 | Form fields still visible and empty | S5 snapshot shows all three textbox elements with no filled values |
| 5 | Screenshot shows error banner | Screenshot shows the step-one form with error message |

---

## Failure Handling

| Symptom | Action |
|---|---|
| URL advances to `checkout-step-two.html` | Critical regression — empty form was accepted. Screenshot → stop → escalate immediately |
| `ERROR_REF` empty after grep | Error banner not rendered. `grep 'heading' tc-chk-001-s5-error.yaml` to inspect all headings. Screenshot → stop |
| Error message text differs (e.g., "Last Name is required") | `eval` exact text. Screenshot → stop → report as validation-order or copy regression |
| "Continue" button not found in S4 | Confirm URL is `checkout-step-one.html`. Re-snapshot once. If absent: screenshot → stop → report |
| Bike Light not listed in S3 cart | Add-to-cart click may not have registered. Check S2 badge. Screenshot → stop → restart session |
