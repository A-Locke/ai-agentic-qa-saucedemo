# TC-AUTH-001 — Successful Login: standard_user

| Field | Value |
|---|---|
| **Test ID** | TC-AUTH-001 |
| **Suite** | Authentication |
| **Title** | Successful login navigates to inventory page |
| **Type** | Positive |

---

## Objective

Verify that `standard_user` authenticates with `secret_sauce`, lands on `/inventory.html`, the "Products" heading is visible, and no error banner appears on the page.

---

## Preconditions

- Fresh browser context — no prior session, cookies, or local storage.
- Network access to `https://www.saucedemo.com/`.

---

## Session Name

```
tc-auth-001-standard-login
```

---

## Steps

Run each command in the same shell session so variables persist. See `scripts/tc-auth-001.sh` for the executable version.

```bash
# 1. Open browser and navigate to the login page
playwright-cli -s=tc-auth-001-standard-login open https://www.saucedemo.com/

# 2. Start tracing
playwright-cli -s=tc-auth-001-standard-login tracing-start

# 3. Snapshot — S1: login page
playwright-cli -s=tc-auth-001-standard-login snapshot --filename=tc-auth-001-s1-login.yaml
# Extract refs:
USERNAME_REF=$(grep 'textbox "Username"' tc-auth-001-s1-login.yaml | grep -o 'ref=e[0-9]*' | cut -d= -f2)
PASSWORD_REF=$(grep 'textbox "Password"' tc-auth-001-s1-login.yaml | grep -o 'ref=e[0-9]*' | cut -d= -f2)
LOGIN_REF=$(grep    'button "Login"'      tc-auth-001-s1-login.yaml | grep -o 'ref=e[0-9]*' | cut -d= -f2)

# 4. Fill credentials
playwright-cli -s=tc-auth-001-standard-login fill "$USERNAME_REF" "standard_user"
playwright-cli -s=tc-auth-001-standard-login fill "$PASSWORD_REF" "secret_sauce"

# 5. Snapshot — S2: confirm form is populated
# Check: textbox "Username" shows "standard_user", textbox "Password" shows "secret_sauce"
playwright-cli -s=tc-auth-001-standard-login snapshot --filename=tc-auth-001-s2-filled.yaml

# 6. Click the login button
playwright-cli -s=tc-auth-001-standard-login click "$LOGIN_REF"

# 7. Snapshot — S3: post-login state
# Check: Page URL contains "inventory.html"; generic: Products visible;
#        no heading matching "Epic sadface" or "Error"
playwright-cli -s=tc-auth-001-standard-login snapshot --filename=tc-auth-001-s3-inventory.yaml
grep 'Page URL'  tc-auth-001-s3-inventory.yaml
grep 'Products'  tc-auth-001-s3-inventory.yaml

# 8. Capture final screenshot
playwright-cli -s=tc-auth-001-standard-login screenshot --filename=tc-auth-001-screenshot.png

# 9. Stop tracing and close
playwright-cli -s=tc-auth-001-standard-login tracing-stop
playwright-cli -s=tc-auth-001-standard-login close
```

---

## Evidence — Pass Criteria

| # | Signal | Where to Confirm |
|---|---|---|
| 1 | URL contains `inventory.html` | S3 snapshot: `grep 'Page URL' tc-auth-001-s3-inventory.yaml` → `https://www.saucedemo.com/inventory.html` |
| 2 | "Products" heading visible | S3 snapshot: `grep 'Products' tc-auth-001-s3-inventory.yaml` → `generic [ref=eXX]: Products` |
| 3 | No error banner visible | S3 snapshot contains no line matching `heading.*Epic sadface` or `heading.*Error` |
| 4 | Screenshot clean — no overlay or error | Screenshot shows the full inventory grid |

---

## Failure Handling

| Symptom | Action |
|---|---|
| `USERNAME_REF` / `PASSWORD_REF` / `LOGIN_REF` empty after grep | S1 snapshot not saved to expected path — check CWD. Re-run from project root |
| URL still at `/` after click (S3) | `grep 'heading.*Epic sadface' tc-auth-001-s3-inventory.yaml` to read error text. Screenshot → stop → report |
| "Products" heading absent in S3 | Confirm URL is correct. Re-snapshot once. If heading never appears: screenshot → stop → report as render regression |
