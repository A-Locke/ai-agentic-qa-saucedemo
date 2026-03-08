#!/usr/bin/env bash
# TC-INV-002 — Add Item Badge Count
# Run from the project root: bash scripts/tc-inv-002.sh
set -euo pipefail

SESSION="tc-inv-002-add-item-badge"
PFX="tc-inv-002"

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

# S2 — inventory page, cart empty
# Cart badge: generic [ref=eXX]: "1" — appears in the first ~15 lines of snapshot when present
playwright-cli -s="$SESSION" snapshot --filename="${PFX}-s2-inventory.yaml"
echo "[S2] $(grep 'Page URL' "${PFX}-s2-inventory.yaml")"
if head -15 "${PFX}-s2-inventory.yaml" | grep -q 'generic.*"[0-9]"'; then
  echo "FAIL: Cart badge visible before adding — context has leaked state" && exit 1
fi
echo "[S2] No cart badge — PASS"

# Product-specific add button: find 'button "Add to cart"' in the section following the product name
ADD_BACKPACK_REF=$(grep -A5 'Sauce Labs Backpack' "${PFX}-s2-inventory.yaml" | grep 'button "Add to cart"' | grep -o 'ref=e[0-9]*' | cut -d= -f2 | head -1)
echo "[S2] ADD_BACKPACK_REF=$ADD_BACKPACK_REF"

playwright-cli -s="$SESSION" click "$ADD_BACKPACK_REF"

# S3 — post-add: badge visible, button changed to Remove
playwright-cli -s="$SESSION" snapshot --filename="${PFX}-s3-after-add.yaml"
CART_BADGE_REF=$(head -15 "${PFX}-s3-after-add.yaml" | grep 'generic.*"[0-9]"' | grep -o 'ref=e[0-9]*' | cut -d= -f2)
echo "[S3] CART_BADGE_REF=$CART_BADGE_REF"
if [ -z "$CART_BADGE_REF" ]; then
  echo "FAIL: Cart badge not found in header after add" && exit 1
fi
grep -A5 'Sauce Labs Backpack' "${PFX}-s3-after-add.yaml" | grep 'button "Remove"' && echo "[S3] Remove button visible — PASS"

echo "[EVIDENCE] Badge text (expected 1):"
playwright-cli -s="$SESSION" eval "el => el.textContent" "$CART_BADGE_REF"

playwright-cli -s="$SESSION" screenshot --filename="${PFX}-screenshot.png"
playwright-cli -s="$SESSION" tracing-stop
playwright-cli -s="$SESSION" close

echo ""
echo "=== TC-INV-002 PASS. Expected: badge=1. Artifacts: ${PFX}-s*.yaml  ${PFX}-screenshot.png ==="
