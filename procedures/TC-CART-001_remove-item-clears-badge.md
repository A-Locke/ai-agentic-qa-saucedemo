# TC-CART-001 — Remove Item: Cart Badge Disappears

| Field | Value |
|---|---|
| **Test ID** | TC-CART-001 |
| **Suite** | Cart |
| **Title** | Removing the only item in cart causes badge to disappear |
| **Type** | Positive |

---

## Objective

Verify that after adding the Sauce Labs Bike Light (badge shows `1`) and clicking "Remove", the cart badge is completely gone from the page — not set to "0" — and the "Add to cart" button is restored for that product.

---

## Preconditions

- Fresh browser context — cart must be empty at the start.
- Credentials: `standard_user` / `secret_sauce`.

---

## Session Name

```
tc-cart-001-remove-clears-badge
```

---

## Steps

Run each command in the same shell session so variables persist. See `scripts/tc-cart-001.sh` for the executable version.

```bash
# 1. Open browser and navigate to the login page
playwright-cli -s=tc-cart-001-remove-clears-badge open https://www.saucedemo.com/

# 2. Start tracing
playwright-cli -s=tc-cart-001-remove-clears-badge tracing-start

# 3. Snapshot — S1: login page
playwright-cli -s=tc-cart-001-remove-clears-badge snapshot --filename=tc-cart-001-s1-login.yaml
# Extract refs:
USERNAME_REF=$(grep 'textbox "Username"' tc-cart-001-s1-login.yaml | grep -o 'ref=e[0-9]*' | cut -d= -f2)
PASSWORD_REF=$(grep 'textbox "Password"' tc-cart-001-s1-login.yaml | grep -o 'ref=e[0-9]*' | cut -d= -f2)
LOGIN_REF=$(grep    'button "Login"'      tc-cart-001-s1-login.yaml | grep -o 'ref=e[0-9]*' | cut -d= -f2)

# 4. Fill credentials and log in
playwright-cli -s=tc-cart-001-remove-clears-badge fill "$USERNAME_REF" "standard_user"
playwright-cli -s=tc-cart-001-remove-clears-badge fill "$PASSWORD_REF" "secret_sauce"
playwright-cli -s=tc-cart-001-remove-clears-badge click "$LOGIN_REF"

# 5. Snapshot — S2: inventory page, cart empty
# Check: URL contains "inventory.html"; no cart badge in header
playwright-cli -s=tc-cart-001-remove-clears-badge snapshot --filename=tc-cart-001-s2-inventory.yaml
# Extract add-to-cart button ref for Bike Light:
ADD_BIKE_LIGHT_REF=$(grep -A5 'Sauce Labs Bike Light' tc-cart-001-s2-inventory.yaml | grep 'button "Add to cart"' | grep -o 'ref=e[0-9]*' | cut -d= -f2 | head -1)

# 6. Add Sauce Labs Bike Light to cart
playwright-cli -s=tc-cart-001-remove-clears-badge click "$ADD_BIKE_LIGHT_REF"

# 7. Snapshot — S3: badge shows "1", button changed to Remove
playwright-cli -s=tc-cart-001-remove-clears-badge snapshot --filename=tc-cart-001-s3-after-add.yaml
# Extract cart badge ref (first ~15 lines, generic [ref=eXX]: "1"):
CART_BADGE_REF=$(head -15 tc-cart-001-s3-after-add.yaml | grep 'generic.*"[0-9]"' | grep -o 'ref=e[0-9]*' | cut -d= -f2)
# Extract remove button ref:
REMOVE_REF=$(grep 'button "Remove"' tc-cart-001-s3-after-add.yaml | grep -o 'ref=e[0-9]*' | cut -d= -f2 | head -1)
playwright-cli -s=tc-cart-001-remove-clears-badge eval "el => el.textContent" "$CART_BADGE_REF"

# 8. Remove the item
playwright-cli -s=tc-cart-001-remove-clears-badge click "$REMOVE_REF"

# 9. Snapshot — S4: post-remove state
# Check: badge completely gone (the element disappears — it does not show "0");
#        "Add to cart" button restored for Bike Light
playwright-cli -s=tc-cart-001-remove-clears-badge snapshot --filename=tc-cart-001-s4-after-remove.yaml
# Verify badge is absent:
head -15 tc-cart-001-s4-after-remove.yaml | grep 'generic.*"[0-9]"'
# (no output = badge absent = PASS)
# Verify "Add to cart" restored:
grep -A5 'Sauce Labs Bike Light' tc-cart-001-s4-after-remove.yaml | grep 'button "Add to cart"'

# 10. Capture final screenshot
playwright-cli -s=tc-cart-001-remove-clears-badge screenshot --filename=tc-cart-001-screenshot.png

# 11. Stop tracing and close
playwright-cli -s=tc-cart-001-remove-clears-badge tracing-stop
playwright-cli -s=tc-cart-001-remove-clears-badge close
```

---

## Evidence — Pass Criteria

| # | Signal | Where to Confirm |
|---|---|---|
| 1 | Cart badge absent in S2 | S2 snapshot first 15 lines: `head -15 tc-cart-001-s2-inventory.yaml \| grep 'generic.*"[0-9]"'` — no output |
| 2 | Cart badge shows `1` in S3 | `eval` on `$CART_BADGE_REF` returns `1` |
| 3 | Cart badge **gone** in S4 | S4 snapshot first 15 lines: `head -15 tc-cart-001-s4-after-remove.yaml \| grep 'generic.*"[0-9]"'` — no output |
| 4 | "Add to cart" restored for Bike Light | S4 snapshot: `grep -A5 'Sauce Labs Bike Light' ... \| grep 'button "Add to cart"'` returns a match |
| 5 | "Remove" button no longer present | S4 snapshot: `grep 'button "Remove"' tc-cart-001-s4-after-remove.yaml` — no output |
| 6 | Screenshot shows header with no badge | Screenshot shows the inventory page header without a badge |

---

## Failure Handling

| Symptom | Action |
|---|---|
| Badge shows `0` instead of disappearing | App is incorrectly showing a zero-count badge. `eval` exact text. Screenshot → stop → report as regression |
| Badge still shows `1` after remove click | Re-snapshot once. Note whether "Remove" or "Add to cart" is shown. Screenshot → stop → report |
| "Add to cart" button not restored in S4 | Re-snapshot once. If button label did not revert: screenshot → stop → report as state inconsistency |
| `REMOVE_REF` empty in S3 | Add-to-cart click may not have registered. Check if `CART_BADGE_REF` is also empty. If so: re-click `$ADD_BIKE_LIGHT_REF`, re-snapshot S3 |
