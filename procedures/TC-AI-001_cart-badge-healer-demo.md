# TC-AI-001 — [AI Healer Demo] Cart Badge Locator Drift

| Field | Value |
|---|---|
| **Test ID** | TC-AI-001 |
| **Suite** | Negative / AI Demo |
| **Title** | Cart badge count is visible and correct after adding one item — with healer annotation for locator drift |
| **Type** | AI Demo (deterministic test; healer annotation is advisory) |

---

## Objective

Verify that adding the Sauce Labs Fleece Jacket renders a header badge showing `1` and switches the product button to "Remove". This test also demonstrates the AI Healer recovery pattern: if the cart badge's stable identifier changes in a future app version, the Drift Recovery Notes section guides re-identification from a fresh snapshot without hardcoding new selectors.

---

## Preconditions

- Fresh browser context — cart badge not visible at login.
- Credentials: `standard_user` / `secret_sauce`.
- Item to add: Sauce Labs Fleece Jacket.

---

## Session Name

```
tc-ai-001-healer-badge-drift
```

---

## Steps

Run each command in the same shell session so variables persist. See `scripts/tc-ai-001.sh` for the executable version.

```bash
# 1. Open browser and navigate to the login page
playwright-cli -s=tc-ai-001-healer-badge-drift open https://www.saucedemo.com/

# 2. Start tracing
playwright-cli -s=tc-ai-001-healer-badge-drift tracing-start

# 3. Snapshot — S1: login page
playwright-cli -s=tc-ai-001-healer-badge-drift snapshot --filename=tc-ai-001-s1-login.yaml
# Extract refs:
USERNAME_REF=$(grep 'textbox "Username"' tc-ai-001-s1-login.yaml | grep -o 'ref=e[0-9]*' | cut -d= -f2)
PASSWORD_REF=$(grep 'textbox "Password"' tc-ai-001-s1-login.yaml | grep -o 'ref=e[0-9]*' | cut -d= -f2)
LOGIN_REF=$(grep    'button "Login"'      tc-ai-001-s1-login.yaml | grep -o 'ref=e[0-9]*' | cut -d= -f2)

# 4. Fill credentials and log in
playwright-cli -s=tc-ai-001-healer-badge-drift fill "$USERNAME_REF" "standard_user"
playwright-cli -s=tc-ai-001-healer-badge-drift fill "$PASSWORD_REF" "secret_sauce"
playwright-cli -s=tc-ai-001-healer-badge-drift click "$LOGIN_REF"

# 5. Snapshot — S2: inventory page, cart empty
# Check: URL contains "inventory.html"; no cart badge in header
playwright-cli -s=tc-ai-001-healer-badge-drift snapshot --filename=tc-ai-001-s2-inventory.yaml
grep 'Page URL' tc-ai-001-s2-inventory.yaml
head -15 tc-ai-001-s2-inventory.yaml | grep 'generic.*"[0-9]"'
# (no output = cart is empty = PASS)
# Extract add-to-cart ref for Fleece Jacket:
ADD_FLEECE_REF=$(grep -A5 'Sauce Labs Fleece Jacket' tc-ai-001-s2-inventory.yaml | grep 'button "Add to cart"' | grep -o 'ref=e[0-9]*' | cut -d= -f2 | head -1)

# 6. Add Fleece Jacket to cart
# [HEALER WATCH POINT — if badge cannot be located in S3, engage Drift Recovery Notes]
playwright-cli -s=tc-ai-001-healer-badge-drift click "$ADD_FLEECE_REF"

# 7. Snapshot — S3: post-add state
# Check: cart badge visible in header; badge shows "1"; Fleece Jacket button now reads "Remove"
# Badge appears as: generic [ref=eXX]: "1" in the first ~15 lines of the snapshot (header area)
# If badge cannot be located in S3: engage Drift Recovery Notes below.
playwright-cli -s=tc-ai-001-healer-badge-drift snapshot --filename=tc-ai-001-s3-after-add.yaml
head -15 tc-ai-001-s3-after-add.yaml | grep 'generic.*"[0-9]"'
grep -A5 'Sauce Labs Fleece Jacket' tc-ai-001-s3-after-add.yaml | grep 'button "Remove"'
# Extract cart badge ref:
CART_BADGE_REF=$(head -15 tc-ai-001-s3-after-add.yaml | grep 'generic.*"[0-9]"' | grep -o 'ref=e[0-9]*' | cut -d= -f2)

# 8. Read badge text to confirm value
playwright-cli -s=tc-ai-001-healer-badge-drift eval "el => el.textContent" "$CART_BADGE_REF"

# 9. Capture final screenshot
playwright-cli -s=tc-ai-001-healer-badge-drift screenshot --filename=tc-ai-001-screenshot.png

# 10. Stop tracing and close
playwright-cli -s=tc-ai-001-healer-badge-drift tracing-stop
playwright-cli -s=tc-ai-001-healer-badge-drift close
```

---

## Evidence — Pass Criteria

| # | Signal | Where to Confirm |
|---|---|---|
| 1 | Cart badge **not visible** in S2 | S2 snapshot first 15 lines: `head -15 tc-ai-001-s2-inventory.yaml \| grep 'generic.*"[0-9]"'` — no output |
| 2 | Cart badge **visible** in S3 | S3 snapshot first 15 lines: `head -15 tc-ai-001-s3-after-add.yaml \| grep 'generic.*"[0-9]"'` returns a match |
| 3 | Badge text equals `1` | `eval` on `$CART_BADGE_REF` returns `1` |
| 4 | "Remove" button visible for Fleece Jacket | S3 snapshot: `grep -A5 'Sauce Labs Fleece Jacket' ... \| grep 'button "Remove"'` returns a match |
| 5 | Screenshot shows badge in header | Screenshot shows header with badge "1" and inventory page |

---

## Drift Recovery Notes

> **Advisory only — engage this section only if the cart badge cannot be located in the S3 snapshot.**
> The test is fully deterministic under normal conditions. This procedure covers recovery from a locator-identifier change in a future app version.

### Simulated Break Scenario

The app ships a rename: the cart badge's stable identifier changes (e.g., the attribute is removed entirely or renamed). The standard badge lookup in S3 yields no output from `head -15 ... | grep 'generic.*"[0-9]"'`.

### Recovery Procedure

**Step 1 — Take a fresh snapshot**

```bash
playwright-cli -s=tc-ai-001-healer-badge-drift snapshot --filename=tc-ai-001-s3-recovery.yaml
```

**Step 2 — Locate the numeric badge by structural proximity**

```bash
head -20 tc-ai-001-s3-recovery.yaml
```

Search for:
- A text node showing `"1"` that sits inside or adjacent to the cart icon link in the header
- Any element whose visible label or accessible name includes `"1"` within the header area

Inspect the cart link element itself — it may now carry an accessible name that includes the count.

**Step 3 — Identify a replacement ref**

From the fresh snapshot, use the first applicable option:

| Priority | What to Look For | When to Use |
|---|---|---|
| 1 | Child element of the cart link showing `"1"` | Badge is still a child of the cart link element |
| 2 | Cart link whose accessible name includes `"1"` | Cart link itself now exposes the count in its label |
| 3 | Nearest element with text `"1"` near the header cart area | Badge has moved but is still structurally nearby |

Assign this ref as `CART_BADGE_RECOVERED_REF`.

**Step 4 — Verify using the recovered ref**

```bash
playwright-cli -s=tc-ai-001-healer-badge-drift eval "el => el.textContent" "$CART_BADGE_RECOVERED_REF"
# Expected output: 1
```

**Step 5 — Record and escalate**

- Note the original element description and the recovered ref in a drift log.
- The assertion intent is unchanged: badge must be **visible** and text must equal **`1`**.
- File a locator-update task for `tests/negative.spec.ts` to replace the broken identifier with the stable recovered ref, then rerun to confirm a deterministic pass.

---

## Failure Handling

| Symptom | Action |
|---|---|
| Badge not visible in S3, "Remove" button also absent | Add-to-cart click did not register. Re-snapshot. If button still reads "Add to cart": re-click `$ADD_FLEECE_REF` then re-snapshot |
| Badge not visible in S3, but "Remove" button IS visible | Badge identifier has drifted — engage Drift Recovery Notes above |
| Badge shows value other than `1` | Cart was not empty at start. `eval` exact value. Screenshot → stop → restart with clean session |
| Recovered ref resolves to wrong element | Re-examine the fresh snapshot manually. Confirm the "1" node is in the header area, not a product price or quantity |
