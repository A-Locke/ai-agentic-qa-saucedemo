# TC-CHK-002 — Checkout Validation: Missing Postal Code

| Field | Value |
|---|---|
| **Test ID** | TC-CHK-002 |
| **Suite** | Checkout |
| **Title** | Submitting checkout info form without postal code shows "Postal Code is required" |
| **Type** | Boundary |

---

## Objective

Verify that filling First Name and Last Name but leaving Postal Code empty blocks checkout progression and displays the error "Postal Code is required". Tests the boundary condition where partial form completion is submitted.

---

## Preconditions

- Fresh browser context.
- Credentials: `standard_user` / `secret_sauce`.
- One item in cart (Sauce Labs Onesie added during setup).
- Test dataset `missing_postal`: First Name `Jane`, Last Name `Doe`, Postal Code _(empty)_.

---

## Session Name

```
tc-chk-002-missing-postal-validation
```

---

## Steps

Run each command in the same shell session so variables persist. See `scripts/tc-chk-002.sh` for the executable version.

```bash
# 1. Open browser and navigate to the login page
playwright-cli -s=tc-chk-002-missing-postal-validation open https://www.saucedemo.com/

# 2. Start tracing
playwright-cli -s=tc-chk-002-missing-postal-validation tracing-start

# 3. Snapshot — S1: login page
playwright-cli -s=tc-chk-002-missing-postal-validation snapshot --filename=tc-chk-002-s1-login.yaml
# Extract refs:
USERNAME_REF=$(grep 'textbox "Username"' tc-chk-002-s1-login.yaml | grep -o 'ref=e[0-9]*' | cut -d= -f2)
PASSWORD_REF=$(grep 'textbox "Password"' tc-chk-002-s1-login.yaml | grep -o 'ref=e[0-9]*' | cut -d= -f2)
LOGIN_REF=$(grep    'button "Login"'      tc-chk-002-s1-login.yaml | grep -o 'ref=e[0-9]*' | cut -d= -f2)

# 4. Fill credentials and log in
playwright-cli -s=tc-chk-002-missing-postal-validation fill "$USERNAME_REF" "standard_user"
playwright-cli -s=tc-chk-002-missing-postal-validation fill "$PASSWORD_REF" "secret_sauce"
playwright-cli -s=tc-chk-002-missing-postal-validation click "$LOGIN_REF"

# 5. Snapshot — S2: inventory page — add Onesie for setup
playwright-cli -s=tc-chk-002-missing-postal-validation snapshot --filename=tc-chk-002-s2-inventory.yaml
ADD_ONESIE_REF=$(grep -A5 'Sauce Labs Onesie' tc-chk-002-s2-inventory.yaml | grep 'button "Add to cart"' | grep -o 'ref=e[0-9]*' | cut -d= -f2 | head -1)
playwright-cli -s=tc-chk-002-missing-postal-validation click "$ADD_ONESIE_REF"

# 6. Navigate to cart
# Note: the cart link is NOT exposed in the accessibility tree — use goto
playwright-cli -s=tc-chk-002-missing-postal-validation goto https://www.saucedemo.com/cart.html

# 7. Snapshot — S3: cart page
# Check: URL contains "cart.html"
playwright-cli -s=tc-chk-002-missing-postal-validation snapshot --filename=tc-chk-002-s3-cart.yaml
CHECKOUT_REF=$(grep 'button "Checkout"' tc-chk-002-s3-cart.yaml | grep -o 'ref=e[0-9]*' | cut -d= -f2)

# 8. Proceed to checkout step one
playwright-cli -s=tc-chk-002-missing-postal-validation click "$CHECKOUT_REF"

# 9. Snapshot — S4: checkout step one
# Check: URL contains "checkout-step-one.html"
# Note: field label is textbox "Zip/Postal Code" (not just "Postal Code")
playwright-cli -s=tc-chk-002-missing-postal-validation snapshot --filename=tc-chk-002-s4-step-one.yaml
grep 'Page URL' tc-chk-002-s4-step-one.yaml
FNAME_REF=$(grep    'textbox "First Name"' tc-chk-002-s4-step-one.yaml | grep -o 'ref=e[0-9]*' | cut -d= -f2)
LNAME_REF=$(grep    'textbox "Last Name"'  tc-chk-002-s4-step-one.yaml | grep -o 'ref=e[0-9]*' | cut -d= -f2)
CONTINUE_REF=$(grep 'button "Continue"'    tc-chk-002-s4-step-one.yaml | grep -o 'ref=e[0-9]*' | cut -d= -f2)

# 10. Fill First Name and Last Name — leave Zip/Postal Code empty
playwright-cli -s=tc-chk-002-missing-postal-validation fill "$FNAME_REF" "Jane"
playwright-cli -s=tc-chk-002-missing-postal-validation fill "$LNAME_REF" "Doe"
# Do NOT fill Zip/Postal Code

# 11. Snapshot — S5: confirm partial fill before submitting
# Check: "Jane" in First Name, "Doe" in Last Name, Zip/Postal Code field empty
playwright-cli -s=tc-chk-002-missing-postal-validation snapshot --filename=tc-chk-002-s5-partial.yaml
grep 'textbox "First Name"'      tc-chk-002-s5-partial.yaml
grep 'textbox "Last Name"'       tc-chk-002-s5-partial.yaml
grep 'textbox "Zip/Postal Code"' tc-chk-002-s5-partial.yaml

# 12. Submit
playwright-cli -s=tc-chk-002-missing-postal-validation click "$CONTINUE_REF"

# 13. Snapshot — S6: post-submit error state
# Check: URL still contains "checkout-step-one.html"
# Error element: heading "Error: Postal Code is required" [level=3] [ref=eXX]
playwright-cli -s=tc-chk-002-missing-postal-validation snapshot --filename=tc-chk-002-s6-error.yaml
grep 'Page URL'       tc-chk-002-s6-error.yaml
grep 'heading.*Error' tc-chk-002-s6-error.yaml
# Extract error ref:
ERROR_REF=$(grep 'heading.*Error' tc-chk-002-s6-error.yaml | grep -o 'ref=e[0-9]*' | cut -d= -f2)

# 14. Read error text to confirm exact message
playwright-cli -s=tc-chk-002-missing-postal-validation eval "el => el.textContent" "$ERROR_REF"

# 15. Capture final screenshot
playwright-cli -s=tc-chk-002-missing-postal-validation screenshot --filename=tc-chk-002-screenshot.png

# 16. Stop tracing and close
playwright-cli -s=tc-chk-002-missing-postal-validation tracing-stop
playwright-cli -s=tc-chk-002-missing-postal-validation close
```

---

## Evidence — Pass Criteria

| # | Signal | Where to Confirm |
|---|---|---|
| 1 | URL remains at `checkout-step-one.html` | S6 snapshot: `grep 'Page URL' tc-chk-002-s6-error.yaml` → still contains `checkout-step-one.html` |
| 2 | Error banner visible on page | S6 snapshot: `grep 'heading.*Error' tc-chk-002-s6-error.yaml` returns a match |
| 3 | Error text is "Postal Code is required" | `eval` on `$ERROR_REF` returns `Error: Postal Code is required` |
| 4 | First Name shows "Jane", Last Name shows "Doe" | S6 snapshot shows both values still present in the form |
| 5 | Screenshot shows postal code error | Screenshot shows step-one with error banner |

---

## Failure Handling

| Symptom | Action |
|---|---|
| URL advances to `checkout-step-two.html` | Critical regression — incomplete address accepted. Screenshot → stop → escalate |
| Error reads "First Name is required" | First Name was not filled. `grep 'textbox "First Name"' tc-chk-002-s5-partial.yaml` to check value. Re-fill and retry |
| Error reads "Last Name is required" | Last Name was not filled. `grep 'textbox "Last Name"' tc-chk-002-s5-partial.yaml` to check value. Re-fill and retry |
| `Zip/Postal Code` field shows a value in S5 | Browser autofill interfered. Extract the ref: `grep 'textbox "Zip/Postal Code"' tc-chk-002-s5-partial.yaml \| grep -o 'ref=e[0-9]*' \| cut -d= -f2`, clear the field, re-snapshot S5, then submit |
| "Continue" button not found in S4 | Confirm URL is `checkout-step-one.html`. Re-snapshot once. If absent: screenshot → stop → report |
