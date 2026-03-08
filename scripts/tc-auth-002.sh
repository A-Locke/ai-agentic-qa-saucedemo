#!/usr/bin/env bash
# TC-AUTH-002 — Locked-Out User Login Error
# Run from the project root: bash scripts/tc-auth-002.sh
set -euo pipefail

SESSION="tc-auth-002-locked-out-error"
PFX="tc-auth-002"

playwright-cli -s="$SESSION" open https://www.saucedemo.com/
playwright-cli -s="$SESSION" tracing-start

# S1 — login page
playwright-cli -s="$SESSION" snapshot --filename="${PFX}-s1-login.yaml"
USERNAME_REF=$(grep 'textbox "Username"' "${PFX}-s1-login.yaml" | grep -o 'ref=e[0-9]*' | cut -d= -f2)
PASSWORD_REF=$(grep 'textbox "Password"' "${PFX}-s1-login.yaml" | grep -o 'ref=e[0-9]*' | cut -d= -f2)
LOGIN_REF=$(grep    'button "Login"'      "${PFX}-s1-login.yaml" | grep -o 'ref=e[0-9]*' | cut -d= -f2)
echo "[S1] USERNAME=$USERNAME_REF  PASSWORD=$PASSWORD_REF  LOGIN=$LOGIN_REF"

playwright-cli -s="$SESSION" fill "$USERNAME_REF" "locked_out_user"
playwright-cli -s="$SESSION" fill "$PASSWORD_REF" "secret_sauce"

# S2 — confirm form is populated
playwright-cli -s="$SESSION" snapshot --filename="${PFX}-s2-filled.yaml"
echo "[S2] $(grep 'textbox "Username"' "${PFX}-s2-filled.yaml")"

playwright-cli -s="$SESSION" click "$LOGIN_REF"

# S3 — post-submit state (must stay on login page with error banner)
playwright-cli -s="$SESSION" snapshot --filename="${PFX}-s3-error.yaml"
echo "[S3] $(grep 'Page URL' "${PFX}-s3-error.yaml")"
if grep -q 'inventory.html' "${PFX}-s3-error.yaml"; then
  echo "FAIL: locked_out_user should not reach inventory" && exit 1
fi
ERROR_REF=$(grep 'heading.*Epic sadface' "${PFX}-s3-error.yaml" | grep -o 'ref=e[0-9]*' | cut -d= -f2)
echo "[S3] ERROR_REF=$ERROR_REF"

playwright-cli -s="$SESSION" eval "el => el.textContent" "$ERROR_REF"

playwright-cli -s="$SESSION" screenshot --filename="${PFX}-screenshot.png"
playwright-cli -s="$SESSION" tracing-stop
playwright-cli -s="$SESSION" close

echo ""
echo "=== TC-AUTH-002 PASS. Expected error: 'Epic sadface: Sorry, this user has been locked out.' ==="
echo "    Artifacts: ${PFX}-s*.yaml  ${PFX}-screenshot.png"
