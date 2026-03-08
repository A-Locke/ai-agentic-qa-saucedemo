#!/usr/bin/env bash
# TC-CHK-001 — Empty Fields Validation: First Name is required
# Run from the project root: bash scripts/tc-chk-001.sh
set -euo pipefail

SESSION="tc-chk-001-empty-fields-validation"
PFX="tc-chk-001"

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

# S2 — inventory page: add Bike Light for setup
playwright-cli -s="$SESSION" snapshot --filename="${PFX}-s2-inventory.yaml"
ADD_BIKE_LIGHT_REF=$(grep -A5 'Sauce Labs Bike Light' "${PFX}-s2-inventory.yaml" | grep 'button "Add to cart"' | grep -o 'ref=e[0-9]*' | cut -d= -f2 | head -1)
playwright-cli -s="$SESSION" click "$ADD_BIKE_LIGHT_REF"

# Navigate to cart via goto — cart link is not exposed in the accessibility tree
playwright-cli -s="$SESSION" goto https://www.saucedemo.com/cart.html

# S3 — cart page
playwright-cli -s="$SESSION" snapshot --filename="${PFX}-s3-cart.yaml"
echo "[S3] $(grep 'Page URL' "${PFX}-s3-cart.yaml")"
CHECKOUT_REF=$(grep 'button "Checkout"' "${PFX}-s3-cart.yaml" | grep -o 'ref=e[0-9]*' | cut -d= -f2)
playwright-cli -s="$SESSION" click "$CHECKOUT_REF"

# S4 — checkout step one (all fields empty)
playwright-cli -s="$SESSION" snapshot --filename="${PFX}-s4-step-one.yaml"
echo "[S4] $(grep 'Page URL' "${PFX}-s4-step-one.yaml")"
CONTINUE_REF=$(grep 'button "Continue"' "${PFX}-s4-step-one.yaml" | grep -o 'ref=e[0-9]*' | cut -d= -f2)
# Do NOT fill any fields

playwright-cli -s="$SESSION" click "$CONTINUE_REF"

# S5 — post-submit: error visible, URL unchanged
# Error appears as: heading "Error: First Name is required" [level=3]
playwright-cli -s="$SESSION" snapshot --filename="${PFX}-s5-error.yaml"
echo "[S5] $(grep 'Page URL' "${PFX}-s5-error.yaml")"
if grep -q 'checkout-step-two.html' "${PFX}-s5-error.yaml"; then
  echo "FAIL: Form advanced without required fields" && exit 1
fi
ERROR_REF=$(grep 'heading.*Error' "${PFX}-s5-error.yaml" | grep -o 'ref=e[0-9]*' | cut -d= -f2)
echo "[S5] ERROR_REF=$ERROR_REF"

echo "[EVIDENCE] Error text (expected 'Error: First Name is required'):"
playwright-cli -s="$SESSION" eval "el => el.textContent" "$ERROR_REF"

playwright-cli -s="$SESSION" screenshot --filename="${PFX}-screenshot.png"
playwright-cli -s="$SESSION" tracing-stop
playwright-cli -s="$SESSION" close

echo ""
echo "=== TC-CHK-001 PASS. Artifacts: ${PFX}-s*.yaml  ${PFX}-screenshot.png ==="
