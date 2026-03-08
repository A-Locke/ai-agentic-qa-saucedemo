# TC-AUTH-002 — Failed Login: locked_out_user

| Field | Value |
|---|---|
| **Test ID** | TC-AUTH-002 |
| **Suite** | Authentication |
| **Title** | Locked-out user sees correct error banner |
| **Type** | Negative |

---

## Objective

Verify that `locked_out_user` is rejected at login: the URL must not advance to `/inventory.html`, an error banner containing "locked out" must appear, and the cart icon must be absent from the page (confirming the user is not authenticated).

---

## Preconditions

- Fresh browser context — no prior session.
- Network access to `https://www.saucedemo.com/`.

---

## Session Name

```
tc-auth-002-locked-out-error
```

---

## Steps

Run each command in the same shell session so variables persist. See `scripts/tc-auth-002.sh` for the executable version.

```bash
# 1. Open browser and navigate to the login page
playwright-cli -s=tc-auth-002-locked-out-error open https://www.saucedemo.com/

# 2. Start tracing
playwright-cli -s=tc-auth-002-locked-out-error tracing-start

# 3. Snapshot — S1: login page
playwright-cli -s=tc-auth-002-locked-out-error snapshot --filename=tc-auth-002-s1-login.yaml
# Extract refs:
USERNAME_REF=$(grep 'textbox "Username"' tc-auth-002-s1-login.yaml | grep -o 'ref=e[0-9]*' | cut -d= -f2)
PASSWORD_REF=$(grep 'textbox "Password"' tc-auth-002-s1-login.yaml | grep -o 'ref=e[0-9]*' | cut -d= -f2)
LOGIN_REF=$(grep    'button "Login"'      tc-auth-002-s1-login.yaml | grep -o 'ref=e[0-9]*' | cut -d= -f2)

# 4. Fill credentials with locked_out_user
playwright-cli -s=tc-auth-002-locked-out-error fill "$USERNAME_REF" "locked_out_user"
playwright-cli -s=tc-auth-002-locked-out-error fill "$PASSWORD_REF" "secret_sauce"

# 5. Snapshot — S2: confirm form is populated
# Check: textbox "Username" shows "locked_out_user"
playwright-cli -s=tc-auth-002-locked-out-error snapshot --filename=tc-auth-002-s2-filled.yaml

# 6. Click the login button
playwright-cli -s=tc-auth-002-locked-out-error click "$LOGIN_REF"

# 7. Snapshot — S3: post-submit state
# Check: Page URL still saucedemo.com/ (not inventory.html);
#        heading matching "Epic sadface" is visible
# Error element in accessibility tree:
#   heading "Epic sadface: Sorry, this user has been locked out." [level=3] [ref=eXX]
playwright-cli -s=tc-auth-002-locked-out-error snapshot --filename=tc-auth-002-s3-error.yaml
grep 'Page URL'             tc-auth-002-s3-error.yaml
grep 'heading.*Epic sadface' tc-auth-002-s3-error.yaml
# Extract error ref:
ERROR_REF=$(grep 'heading.*Epic sadface' tc-auth-002-s3-error.yaml | grep -o 'ref=e[0-9]*' | cut -d= -f2)

# 8. Read error banner text to confirm exact message
playwright-cli -s=tc-auth-002-locked-out-error eval "el => el.textContent" "$ERROR_REF"

# 9. Capture final screenshot
playwright-cli -s=tc-auth-002-locked-out-error screenshot --filename=tc-auth-002-screenshot.png

# 10. Stop tracing and close
playwright-cli -s=tc-auth-002-locked-out-error tracing-stop
playwright-cli -s=tc-auth-002-locked-out-error close
```

---

## Evidence — Pass Criteria

| # | Signal | Where to Confirm |
|---|---|---|
| 1 | URL does **not** contain `inventory.html` | S3 snapshot: `grep 'Page URL' tc-auth-002-s3-error.yaml` → `https://www.saucedemo.com/` |
| 2 | Error banner visible on page | S3 snapshot: `grep 'heading.*Epic sadface' tc-auth-002-s3-error.yaml` returns a match |
| 3 | Error text contains "locked out" | `eval` output: `Epic sadface: Sorry, this user has been locked out.` |
| 4 | Cart icon absent from page header | S3 snapshot first 15 lines: no `generic.*"[0-9]"` — no badge, confirming no auth |
| 5 | Screenshot shows error banner on login page | Screenshot shows login form with error message visible |

---

## Failure Handling

| Symptom | Action |
|---|---|
| URL advanced to `inventory.html` | Critical regression — locked user was admitted. Screenshot → stop → escalate immediately |
| `ERROR_REF` empty after grep | Error banner not rendered. `grep 'heading' tc-auth-002-s3-error.yaml` to inspect all headings. Screenshot → stop |
| Error text does not contain "locked out" | Capture exact `eval` output. Stop. Report as copy or logic regression |
| Login button not found in S1 | Re-snapshot once. If still absent: screenshot → `tracing-stop` → note "page did not render" |
