#!/usr/bin/env bash
# TC-AUTH-001 — Successful Login: standard_user
# Run from the project root: bash scripts/tc-auth-001.sh
set -euo pipefail

SESSION="tc-auth-001-standard-login"
PFX="tc-auth-001"

playwright-cli -s="$SESSION" open https://www.saucedemo.com/
playwright-cli -s="$SESSION" tracing-start

# S1 — login page
playwright-cli -s="$SESSION" snapshot --filename="${PFX}-s1-login.yaml"
USERNAME_REF=$(grep 'textbox "Username"' "${PFX}-s1-login.yaml" | grep -o 'ref=e[0-9]*' | cut -d= -f2)
PASSWORD_REF=$(grep 'textbox "Password"' "${PFX}-s1-login.yaml" | grep -o 'ref=e[0-9]*' | cut -d= -f2)
LOGIN_REF=$(grep    'button "Login"'      "${PFX}-s1-login.yaml" | grep -o 'ref=e[0-9]*' | cut -d= -f2)
echo "[S1] USERNAME=$USERNAME_REF  PASSWORD=$PASSWORD_REF  LOGIN=$LOGIN_REF"

playwright-cli -s="$SESSION" fill "$USERNAME_REF" "standard_user"
playwright-cli -s="$SESSION" fill "$PASSWORD_REF" "secret_sauce"

# S2 — confirm form is populated
playwright-cli -s="$SESSION" snapshot --filename="${PFX}-s2-filled.yaml"
echo "[S2] $(grep 'textbox "Username"' "${PFX}-s2-filled.yaml")"

playwright-cli -s="$SESSION" click "$LOGIN_REF"

# S3 — post-login state
playwright-cli -s="$SESSION" snapshot --filename="${PFX}-s3-inventory.yaml"
echo "[S3] $(grep 'Page URL' "${PFX}-s3-inventory.yaml")"
grep 'Products' "${PFX}-s3-inventory.yaml" && echo "[S3] Products heading visible — PASS"
if grep -q 'heading.*Epic sadface\|heading.*Error' "${PFX}-s3-inventory.yaml"; then
  echo "FAIL: Error banner visible in S3" && exit 1
fi

playwright-cli -s="$SESSION" screenshot --filename="${PFX}-screenshot.png"
playwright-cli -s="$SESSION" tracing-stop
playwright-cli -s="$SESSION" close

echo ""
echo "=== TC-AUTH-001 PASS. Artifacts: ${PFX}-s*.yaml  ${PFX}-screenshot.png ==="
