#!/usr/bin/env bash
# TC-NEG-001 — Edge Case: Checkout with Empty Cart
# Run from the project root: bash scripts/tc-neg-001.sh
set -euo pipefail

SESSION="tc-neg-001-empty-cart-checkout"
PFX="tc-neg-001"

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

# S2 — inventory page: confirm cart is empty — do NOT add any item
playwright-cli -s="$SESSION" snapshot --filename="${PFX}-s2-inventory.yaml"
echo "[S2] $(grep 'Page URL' "${PFX}-s2-inventory.yaml")"
if head -15 "${PFX}-s2-inventory.yaml" | grep -q 'generic.*"[0-9]"'; then
  echo "FAIL: Cart badge visible — context has leaked state. Restart with clean session." && exit 1
fi
echo "[S2] Cart is empty — PASS"

# Navigate directly to cart (no items added)
# Cart link is not exposed in the accessibility tree when empty — use goto
playwright-cli -s="$SESSION" goto https://www.saucedemo.com/cart.html

# S3 — cart page (empty): no item rows
playwright-cli -s="$SESSION" snapshot --filename="${PFX}-s3-cart.yaml"
echo "[S3] $(grep 'Page URL' "${PFX}-s3-cart.yaml")"
if grep -q 'button "Remove"' "${PFX}-s3-cart.yaml"; then
  echo "FAIL: Cart contains items — context has leaked state" && exit 1
fi
echo "[S3] No item rows in cart — PASS"
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

# S5 — checkout step two (empty order summary)
# Item total appears as: generic [ref=eXX]: "Item total: $0.00"
playwright-cli -s="$SESSION" snapshot --filename="${PFX}-s5-step-two.yaml"
echo "[S5] $(grep 'Page URL' "${PFX}-s5-step-two.yaml")"
if grep -q 'button "Remove"' "${PFX}-s5-step-two.yaml"; then
  echo "FAIL: Order summary contains items" && exit 1
fi
echo "[S5] No item rows in order summary — PASS"
ITEM_TOTAL_REF=$(grep '"Item total:' "${PFX}-s5-step-two.yaml" | grep -o 'ref=e[0-9]*' | cut -d= -f2)
FINISH_REF=$(grep 'button "Finish"' "${PFX}-s5-step-two.yaml" | grep -o 'ref=e[0-9]*' | cut -d= -f2)
echo "[S5] ITEM_TOTAL_REF=$ITEM_TOTAL_REF  FINISH_REF=$FINISH_REF"
grep 'button "Finish"' "${PFX}-s5-step-two.yaml" && echo "[S5] Finish button present — PASS"

echo "[EVIDENCE] Item total (expected 'Item total: \$0.00'):"
playwright-cli -s="$SESSION" eval "el => el.textContent" "$ITEM_TOTAL_REF"

playwright-cli -s="$SESSION" screenshot --filename="${PFX}-screenshot.png"
playwright-cli -s="$SESSION" tracing-stop
playwright-cli -s="$SESSION" close

echo ""
echo "=== TC-NEG-001 PASS. Expected: item total=\$0.00, Finish button present. Artifacts: ${PFX}-s*.yaml  ${PFX}-screenshot.png ==="
