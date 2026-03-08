# TC-INV-002 — Add Item: Cart Badge Increments to 1

| Field | Value |
|---|---|
| **Test ID** | TC-INV-002 |
| **Suite** | Inventory |
| **Title** | Adding one item to cart shows badge count of 1 |
| **Type** | Positive |

---

## Objective

Verify that clicking "Add to cart" for the Sauce Labs Backpack causes the cart badge to appear in the header showing `1`, and the button label switches to "Remove" — confirming the item is registered in the cart.

---

## Preconditions

- Fresh browser context — cart must be empty (badge not visible, not showing "0").
- Credentials: `standard_user` / `secret_sauce`.

---

## Session Name

```
tc-inv-002-add-item-badge
```

---

## Steps

Run each command in the same shell session so variables persist. See `scripts/tc-inv-002.sh` for the executable version.

```bash
# 1. Open browser and navigate to the login page
playwright-cli -s=tc-inv-002-add-item-badge open https://www.saucedemo.com/

# 2. Start tracing
playwright-cli -s=tc-inv-002-add-item-badge tracing-start

# 3. Snapshot — S1: login page
playwright-cli -s=tc-inv-002-add-item-badge snapshot --filename=tc-inv-002-s1-login.yaml
# Extract refs:
USERNAME_REF=$(grep 'textbox "Username"' tc-inv-002-s1-login.yaml | grep -o 'ref=e[0-9]*' | cut -d= -f2)
PASSWORD_REF=$(grep 'textbox "Password"' tc-inv-002-s1-login.yaml | grep -o 'ref=e[0-9]*' | cut -d= -f2)
LOGIN_REF=$(grep    'button "Login"'      tc-inv-002-s1-login.yaml | grep -o 'ref=e[0-9]*' | cut -d= -f2)

# 4. Fill credentials and log in
playwright-cli -s=tc-inv-002-add-item-badge fill "$USERNAME_REF" "standard_user"
playwright-cli -s=tc-inv-002-add-item-badge fill "$PASSWORD_REF" "secret_sauce"
playwright-cli -s=tc-inv-002-add-item-badge click "$LOGIN_REF"

# 5. Snapshot — S2: inventory page, cart empty
# Check: Page URL contains "inventory.html";
#        no cart badge in header (first ~15 lines contain no generic [ref=eXX]: "1")
# Note: the cart link is NOT exposed in the accessibility tree — the badge element
#       appears only after an item is added: generic [ref=eXX]: "1" in the first ~15 lines
playwright-cli -s=tc-inv-002-add-item-badge snapshot --filename=tc-inv-002-s2-inventory.yaml
grep 'Page URL' tc-inv-002-s2-inventory.yaml
# Extract add-to-cart button ref for Backpack:
# (find 'button "Add to cart"' in the 5 lines following the product name)
ADD_BACKPACK_REF=$(grep -A5 'Sauce Labs Backpack' tc-inv-002-s2-inventory.yaml | grep 'button "Add to cart"' | grep -o 'ref=e[0-9]*' | cut -d= -f2 | head -1)

# 6. Add Sauce Labs Backpack to cart
playwright-cli -s=tc-inv-002-add-item-badge click "$ADD_BACKPACK_REF"

# 7. Snapshot — S3: post-add state
# Check: cart badge visible in header; badge shows "1"; Backpack button now reads "Remove"
playwright-cli -s=tc-inv-002-add-item-badge snapshot --filename=tc-inv-002-s3-after-add.yaml
# Extract cart badge ref (appears in first ~15 lines as: generic [ref=eXX]: "1"):
CART_BADGE_REF=$(head -15 tc-inv-002-s3-after-add.yaml | grep 'generic.*"[0-9]"' | grep -o 'ref=e[0-9]*' | cut -d= -f2)
grep -A5 'Sauce Labs Backpack' tc-inv-002-s3-after-add.yaml | grep 'button "Remove"'

# 8. Read badge text to confirm value
playwright-cli -s=tc-inv-002-add-item-badge eval "el => el.textContent" "$CART_BADGE_REF"

# 9. Capture final screenshot
playwright-cli -s=tc-inv-002-add-item-badge screenshot --filename=tc-inv-002-screenshot.png

# 10. Stop tracing and close
playwright-cli -s=tc-inv-002-add-item-badge tracing-stop
playwright-cli -s=tc-inv-002-add-item-badge close
```

---

## Evidence — Pass Criteria

| # | Signal | Where to Confirm |
|---|---|---|
| 1 | Cart badge **absent** before add | S2 snapshot first 15 lines: no `generic.*"[0-9]"` match |
| 2 | Cart badge **visible** after add | S3 snapshot: `head -15 tc-inv-002-s3-after-add.yaml \| grep 'generic.*"[0-9]"'` returns a match |
| 3 | Badge text equals `1` | `eval` on `$CART_BADGE_REF` returns `1` |
| 4 | "Remove" button visible for Backpack | S3 snapshot: `grep -A5 'Sauce Labs Backpack' ... \| grep 'button "Remove"'` returns a match |
| 5 | Screenshot shows badge in header | Screenshot shows header with badge displaying "1" |

---

## Failure Handling

| Symptom | Action |
|---|---|
| Cart badge already visible in S2 (before add) | Context is not fresh — state leaked. Screenshot → `tracing-stop` → reopen with clean session |
| `ADD_BACKPACK_REF` empty after grep | `grep -A5 'Sauce Labs Backpack' tc-inv-002-s2-inventory.yaml` to inspect the section manually. Re-snapshot once |
| `CART_BADGE_REF` empty in S3 after click | `grep 'generic' tc-inv-002-s3-after-add.yaml | head -20` to inspect header area. Re-snapshot once. If still absent: screenshot → stop → report |
| Badge shows value other than `1` | `eval` the badge text. Screenshot → stop → report as state-leak regression |
