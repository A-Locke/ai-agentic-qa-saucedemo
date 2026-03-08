#!/usr/bin/env bash
# TC-CHK-002 — Missing Postal Code Validation
# Run from the project root: bash scripts/tc-chk-002.sh
set -euo pipefail

SESSION="tc-chk-002-missing-postal-validation"
PFX="tc-chk-002"

playwright-cli -s="$SESSION" open https://www.saucedemo.com/
playwright-cli -s="$SESSION" tracing-start

# S1 — login page
playwright-cli -s="$SESSION" snapshot --filename="${PFX}-s1-login.yaml"
USERNAME_REF=$(grep 'textbox "Username"' "${PFX}-s1-login.yaml" | grep -o 'ref=e[0-9]*' | cut -d= -f2)
PASSWORD_REF=$(grep 'textbox "Password"' "${PFX}-s1-login.yaml" | grep -o 'ref=e[0-9]*' | cut -d= -f2)
LOGIN_REF=$(grep    'button "Login"'      "${PFX}-s1-login.yaml" | grep -o 'ref=e[0-9]*' | cut -d= -f2)

playwright-cli -s="$SESSION" fill "$USERNAME_REF" "standard_user"
playwright-cli -s="$SESSION" fill "$PASSWORD_REF" "secret_sauce"
playwright-cli -s="$SESSION" click "$LOGIN_REF"

# S2 — inventory page: add Onesie for setup
playwright-cli -s="$SESSION" snapshot --filename="${PFX}-s2-inventory.yaml"
ADD_ONESIE_REF=$(grep -A5 'Sauce Labs Onesie' "${PFX}-s2-inventory.yaml" | grep 'button "Add to cart"' | grep -o 'ref=e[0-9]*' | cut -d= -f2 | head -1)
playwright-cli -s="$SESSION" click "$ADD_ONESIE_REF"

# Navigate to cart via goto — cart link is not exposed in the accessibility tree
playwright-cli -s="$SESSION" goto https://www.saucedemo.com/cart.html

# S3 — cart page
playwright-cli -s="$SESSION" snapshot --filename="${PFX}-s3-cart.yaml"
CHECKOUT_REF=$(grep 'button "Checkout"' "${PFX}-s3-cart.yaml" | grep -o 'ref=e[0-9]*' | cut -d= -f2)
playwright-cli -s="$SESSION" click "$CHECKOUT_REF"

# S4 — checkout step one
# Field label is: textbox "Zip/Postal Code" (not just "Postal Code")
playwright-cli -s="$SESSION" snapshot --filename="${PFX}-s4-step-one.yaml"
echo "[S4] $(grep 'Page URL' "${PFX}-s4-step-one.yaml")"
FNAME_REF=$(grep   'textbox "First Name"'      "${PFX}-s4-step-one.yaml" | grep -o 'ref=e[0-9]*' | cut -d= -f2)
LNAME_REF=$(grep   'textbox "Last Name"'       "${PFX}-s4-step-one.yaml" | grep -o 'ref=e[0-9]*' | cut -d= -f2)
CONTINUE_REF=$(grep 'button "Continue"'        "${PFX}-s4-step-one.yaml" | grep -o 'ref=e[0-9]*' | cut -d= -f2)

playwright-cli -s="$SESSION" fill "$FNAME_REF" "Jane"
playwright-cli -s="$SESSION" fill "$LNAME_REF" "Doe"
# Do NOT fill Zip/Postal Code

# S5 — confirm partial fill before submitting
playwright-cli -s="$SESSION" snapshot --filename="${PFX}-s5-partial.yaml"
echo "[S5] First Name: $(grep 'textbox "First Name"'      "${PFX}-s5-partial.yaml")"
echo "[S5] Last Name:  $(grep 'textbox "Last Name"'       "${PFX}-s5-partial.yaml")"
echo "[S5] Postal:     $(grep 'textbox "Zip/Postal Code"' "${PFX}-s5-partial.yaml")"

playwright-cli -s="$SESSION" click "$CONTINUE_REF"

# S6 — post-submit error state
# Error appears as: heading "Error: Postal Code is required" [level=3]
playwright-cli -s="$SESSION" snapshot --filename="${PFX}-s6-error.yaml"
echo "[S6] $(grep 'Page URL' "${PFX}-s6-error.yaml")"
if grep -q 'checkout-step-two.html' "${PFX}-s6-error.yaml"; then
  echo "FAIL: Form advanced without postal code — critical regression" && exit 1
fi
ERROR_REF=$(grep 'heading.*Error' "${PFX}-s6-error.yaml" | grep -o 'ref=e[0-9]*' | cut -d= -f2)
echo "[S6] ERROR_REF=$ERROR_REF"

echo "[EVIDENCE] Error text (expected 'Error: Postal Code is required'):"
playwright-cli -s="$SESSION" eval "el => el.textContent" "$ERROR_REF"

playwright-cli -s="$SESSION" screenshot --filename="${PFX}-screenshot.png"
playwright-cli -s="$SESSION" tracing-stop
playwright-cli -s="$SESSION" close

echo ""
echo "=== TC-CHK-002 PASS. Artifacts: ${PFX}-s*.yaml  ${PFX}-screenshot.png ==="
