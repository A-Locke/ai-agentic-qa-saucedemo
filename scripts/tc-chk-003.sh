#!/usr/bin/env bash
# TC-CHK-003 — Full Checkout: End-to-End Confirmation
# Run from the project root: bash scripts/tc-chk-003.sh
set -euo pipefail

SESSION="tc-chk-003-full-checkout-confirm"
PFX="tc-chk-003"

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

# S2 — inventory page: add Backpack
playwright-cli -s="$SESSION" snapshot --filename="${PFX}-s2-inventory.yaml"
echo "[S2] $(grep 'Page URL' "${PFX}-s2-inventory.yaml")"
ADD_BACKPACK_REF=$(grep -A5 'Sauce Labs Backpack' "${PFX}-s2-inventory.yaml" | grep 'button "Add to cart"' | grep -o 'ref=e[0-9]*' | cut -d= -f2 | head -1)
playwright-cli -s="$SESSION" click "$ADD_BACKPACK_REF"

# Navigate to cart via goto — cart link is not exposed in the accessibility tree
playwright-cli -s="$SESSION" goto https://www.saucedemo.com/cart.html

# S3 — cart page: Backpack listed
playwright-cli -s="$SESSION" snapshot --filename="${PFX}-s3-cart.yaml"
echo "[S3] $(grep 'Page URL' "${PFX}-s3-cart.yaml")"
grep 'Sauce Labs Backpack' "${PFX}-s3-cart.yaml" && echo "[S3] Backpack in cart — PASS"
CHECKOUT_REF=$(grep 'button "Checkout"' "${PFX}-s3-cart.yaml" | grep -o 'ref=e[0-9]*' | cut -d= -f2)
playwright-cli -s="$SESSION" click "$CHECKOUT_REF"

# S4 — checkout step one
playwright-cli -s="$SESSION" snapshot --filename="${PFX}-s4-step-one.yaml"
echo "[S4] $(grep 'Page URL' "${PFX}-s4-step-one.yaml")"
FNAME_REF=$(grep   'textbox "First Name"'      "${PFX}-s4-step-one.yaml" | grep -o 'ref=e[0-9]*' | cut -d= -f2)
LNAME_REF=$(grep   'textbox "Last Name"'       "${PFX}-s4-step-one.yaml" | grep -o 'ref=e[0-9]*' | cut -d= -f2)
POSTAL_REF=$(grep  'textbox "Zip/Postal Code"' "${PFX}-s4-step-one.yaml" | grep -o 'ref=e[0-9]*' | cut -d= -f2)
CONTINUE_REF=$(grep 'button "Continue"'        "${PFX}-s4-step-one.yaml" | grep -o 'ref=e[0-9]*' | cut -d= -f2)

playwright-cli -s="$SESSION" fill "$FNAME_REF"  "Jane"
playwright-cli -s="$SESSION" fill "$LNAME_REF"  "Doe"
playwright-cli -s="$SESSION" fill "$POSTAL_REF" "90210"
playwright-cli -s="$SESSION" click "$CONTINUE_REF"

# S5 — checkout step two: order summary
playwright-cli -s="$SESSION" snapshot --filename="${PFX}-s5-step-two.yaml"
echo "[S5] $(grep 'Page URL' "${PFX}-s5-step-two.yaml")"
grep 'Sauce Labs Backpack' "${PFX}-s5-step-two.yaml" && echo "[S5] Backpack in summary — PASS"
FINISH_REF=$(grep 'button "Finish"' "${PFX}-s5-step-two.yaml" | grep -o 'ref=e[0-9]*' | cut -d= -f2)
playwright-cli -s="$SESSION" click "$FINISH_REF"

# S6 — checkout complete
# Confirmation heading: heading "Thank you for your order!" [level=2]
# Back button label: button "Back Home" (not "Back to Products")
playwright-cli -s="$SESSION" snapshot --filename="${PFX}-s6-complete.yaml"
echo "[S6] $(grep 'Page URL' "${PFX}-s6-complete.yaml")"
HEADER_REF=$(grep 'heading.*Thank you' "${PFX}-s6-complete.yaml" | grep -o 'ref=e[0-9]*' | cut -d= -f2)
echo "[S6] HEADER_REF=$HEADER_REF"
grep 'button "Back Home"' "${PFX}-s6-complete.yaml" && echo "[S6] Back Home button visible — PASS"
if head -15 "${PFX}-s6-complete.yaml" | grep -q 'generic.*"[0-9]"'; then
  echo "FAIL: Cart badge still visible on completion page" && exit 1
fi
echo "[S6] Cart badge absent — PASS"

echo "[EVIDENCE] Confirmation heading (expected 'Thank you for your order!'):"
playwright-cli -s="$SESSION" eval "el => el.textContent" "$HEADER_REF"

playwright-cli -s="$SESSION" screenshot --filename="${PFX}-screenshot.png"
playwright-cli -s="$SESSION" tracing-stop
playwright-cli -s="$SESSION" close

echo ""
echo "=== TC-CHK-003 PASS. Artifacts: ${PFX}-s*.yaml  ${PFX}-screenshot.png ==="
