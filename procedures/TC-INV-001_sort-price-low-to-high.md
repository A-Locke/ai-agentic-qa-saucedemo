# TC-INV-001 — Sort Products: Price (Low to High)

| Field | Value |
|---|---|
| **Test ID** | TC-INV-001 |
| **Suite** | Inventory |
| **Title** | Sort Price (low to high) produces correct ascending price order |
| **Type** | Positive |

---

## Objective

Verify that selecting "Price (low to high)" in the sort dropdown reorders the product list with the cheapest item ($7.99 — Sauce Labs Onesie) first, the most expensive ($49.99 — Sauce Labs Fleece Jacket) last, and no price inversions in between.

---

## Preconditions

- Fresh browser context.
- Credentials: `standard_user` / `secret_sauce`.
- All 6 products visible on inventory page after login.

---

## Session Name

```
tc-inv-001-sort-price-low-high
```

---

## Steps

Run each command in the same shell session so variables persist. See `scripts/tc-inv-001.sh` for the executable version.

```bash
# 1. Open browser and navigate to the login page
playwright-cli -s=tc-inv-001-sort-price-low-high open https://www.saucedemo.com/

# 2. Start tracing
playwright-cli -s=tc-inv-001-sort-price-low-high tracing-start

# 3. Snapshot — S1: login page
playwright-cli -s=tc-inv-001-sort-price-low-high snapshot --filename=tc-inv-001-s1-login.yaml
# Extract refs:
USERNAME_REF=$(grep 'textbox "Username"' tc-inv-001-s1-login.yaml | grep -o 'ref=e[0-9]*' | cut -d= -f2)
PASSWORD_REF=$(grep 'textbox "Password"' tc-inv-001-s1-login.yaml | grep -o 'ref=e[0-9]*' | cut -d= -f2)
LOGIN_REF=$(grep    'button "Login"'      tc-inv-001-s1-login.yaml | grep -o 'ref=e[0-9]*' | cut -d= -f2)

# 4. Fill credentials and log in
playwright-cli -s=tc-inv-001-sort-price-low-high fill "$USERNAME_REF" "standard_user"
playwright-cli -s=tc-inv-001-sort-price-low-high fill "$PASSWORD_REF" "secret_sauce"
playwright-cli -s=tc-inv-001-sort-price-low-high click "$LOGIN_REF"

# 5. Snapshot — S2: inventory page (default sort: Name A to Z)
# Check: Page URL contains "inventory.html"
# Note: the sort dropdown has NO accessible label — it appears as: combobox [ref=eXX]
playwright-cli -s=tc-inv-001-sort-price-low-high snapshot --filename=tc-inv-001-s2-inventory.yaml
grep 'Page URL' tc-inv-001-s2-inventory.yaml
# Extract sort dropdown ref:
SORT_REF=$(grep 'combobox \[ref' tc-inv-001-s2-inventory.yaml | grep -o 'ref=e[0-9]*' | cut -d= -f2)

# 6. Select "Price (low to high)" using option value "lohi"
playwright-cli -s=tc-inv-001-sort-price-low-high select "$SORT_REF" "lohi"

# 7. Snapshot — S3: post-sort state
# Check: option "Price (low to high)" is now [selected]
# Prices appear as: generic [ref=eXX]: $7.99 — head -1 = first (cheapest), tail -1 = last (most expensive)
playwright-cli -s=tc-inv-001-sort-price-low-high snapshot --filename=tc-inv-001-s3-sorted.yaml
grep 'option.*\[selected\]' tc-inv-001-s3-sorted.yaml
# Extract first and last price refs:
FIRST_PRICE_REF=$(grep 'generic.*\$[0-9]' tc-inv-001-s3-sorted.yaml | head -1 | grep -o 'ref=e[0-9]*' | cut -d= -f2)
LAST_PRICE_REF=$(grep  'generic.*\$[0-9]' tc-inv-001-s3-sorted.yaml | tail -1 | grep -o 'ref=e[0-9]*' | cut -d= -f2)

# 8. Read first and last prices to confirm values
playwright-cli -s=tc-inv-001-sort-price-low-high eval "el => el.textContent" "$FIRST_PRICE_REF"
playwright-cli -s=tc-inv-001-sort-price-low-high eval "el => el.textContent" "$LAST_PRICE_REF"

# 9. Capture final screenshot
playwright-cli -s=tc-inv-001-sort-price-low-high screenshot --filename=tc-inv-001-screenshot.png

# 10. Stop tracing and close
playwright-cli -s=tc-inv-001-sort-price-low-high tracing-stop
playwright-cli -s=tc-inv-001-sort-price-low-high close
```

---

## Evidence — Pass Criteria

| # | Signal | Where to Confirm |
|---|---|---|
| 1 | URL contains `inventory.html` | S2 snapshot: `grep 'Page URL' tc-inv-001-s2-inventory.yaml` → `/inventory.html` |
| 2 | Sort dropdown shows "Price (low to high)" | S3 snapshot: `grep 'option.*\[selected\]' tc-inv-001-s3-sorted.yaml` → `option "Price (low to high)" [selected]` |
| 3 | First price is `$7.99` | `eval` on `$FIRST_PRICE_REF` returns `$7.99` |
| 4 | Last price is `$49.99` | `eval` on `$LAST_PRICE_REF` returns `$49.99` |
| 5 | All prices in ascending order | Read all price text from S3: `grep 'generic.*\$[0-9]' tc-inv-001-s3-sorted.yaml` → sequence: $7.99 → $9.99 → $15.99 → $15.99 → $29.99 → $49.99 |
| 6 | Screenshot shows Onesie at top of list | Screenshot shows sorted inventory with Onesie first |

**Expected sort order:** Sauce Labs Onesie ($7.99) → Bike Light ($9.99) → Bolt T-Shirt ($15.99) → Test.allTheThings() T-Shirt ($15.99) → Backpack ($29.99) → Fleece Jacket ($49.99)

---

## Failure Handling

| Symptom | Action |
|---|---|
| `SORT_REF` empty after grep | Sort dropdown not found. `grep 'combobox' tc-inv-001-s2-inventory.yaml` to inspect. Confirm login succeeded (URL check). Re-snapshot once |
| First price is not `$7.99` after select | Re-snapshot once. `grep 'generic.*\$[0-9]' tc-inv-001-s3-sorted.yaml` to read all prices. Screenshot → stop → report as sort regression |
| Price sequence contains an inversion | Record the full price sequence from the grep output. Screenshot → stop → report the first inversion point |
