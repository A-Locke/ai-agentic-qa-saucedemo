#!/usr/bin/env bash
# TC-CART-001 — Remove Item Clears Badge
# Run from the project root: bash scripts/tc-cart-001.sh
set -euo pipefail

SESSION="tc-cart-001-remove-clears-badge"
PFX="tc-cart-001"

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

# S2 — inventory page
playwright-cli -s="$SESSION" snapshot --filename="${PFX}-s2-inventory.yaml"
ADD_BIKE_LIGHT_REF=$(grep -A5 'Sauce Labs Bike Light' "${PFX}-s2-inventory.yaml" | grep 'button "Add to cart"' | grep -o 'ref=e[0-9]*' | cut -d= -f2 | head -1)
echo "[S2] ADD_BIKE_LIGHT_REF=$ADD_BIKE_LIGHT_REF"

playwright-cli -s="$SESSION" click "$ADD_BIKE_LIGHT_REF"

# S3 — after add: badge = "1", button changed to Remove
playwright-cli -s="$SESSION" snapshot --filename="${PFX}-s3-after-add.yaml"
CART_BADGE_REF=$(head -15 "${PFX}-s3-after-add.yaml" | grep 'generic.*"[0-9]"' | grep -o 'ref=e[0-9]*' | cut -d= -f2)
REMOVE_REF=$(grep 'button "Remove"' "${PFX}-s3-after-add.yaml" | grep -o 'ref=e[0-9]*' | cut -d= -f2 | head -1)
echo "[S3] CART_BADGE_REF=$CART_BADGE_REF  REMOVE_REF=$REMOVE_REF"
if [ -z "$CART_BADGE_REF" ]; then
  echo "FAIL: Cart badge not found after add" && exit 1
fi
echo "[S3] Cart badge visible — PASS"

playwright-cli -s="$SESSION" click "$REMOVE_REF"

# S4 — after remove: badge completely absent (not 0 — the element disappears)
playwright-cli -s="$SESSION" snapshot --filename="${PFX}-s4-after-remove.yaml"
if head -15 "${PFX}-s4-after-remove.yaml" | grep -q 'generic.*"[0-9]"'; then
  echo "FAIL: Cart badge still visible after remove" && exit 1
fi
echo "[S4] Cart badge absent — PASS"
grep -A5 'Sauce Labs Bike Light' "${PFX}-s4-after-remove.yaml" | grep 'button "Add to cart"' \
  && echo "[S4] Add to cart button restored — PASS"

playwright-cli -s="$SESSION" screenshot --filename="${PFX}-screenshot.png"
playwright-cli -s="$SESSION" tracing-stop
playwright-cli -s="$SESSION" close

echo ""
echo "=== TC-CART-001 PASS. Artifacts: ${PFX}-s*.yaml  ${PFX}-screenshot.png ==="
