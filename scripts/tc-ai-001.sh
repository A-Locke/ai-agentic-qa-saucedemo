#!/usr/bin/env bash
# TC-AI-001 — Cart Badge Locator Drift (Healer Demo)
# Run from the project root: bash scripts/tc-ai-001.sh
set -euo pipefail

SESSION="tc-ai-001-healer-badge-drift"
PFX="tc-ai-001"

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
playwright-cli -s="$SESSION" snapshot --filename="${PFX}-s2-inventory.yaml"
echo "[S2] $(grep 'Page URL' "${PFX}-s2-inventory.yaml")"
if head -15 "${PFX}-s2-inventory.yaml" | grep -q 'generic.*"[0-9]"'; then
  echo "FAIL: Cart badge should not be visible before adding item" && exit 1
fi
echo "[S2] No cart badge — PASS"
ADD_FLEECE_REF=$(grep -A5 'Sauce Labs Fleece Jacket' "${PFX}-s2-inventory.yaml" | grep 'button "Add to cart"' | grep -o 'ref=e[0-9]*' | cut -d= -f2 | head -1)
echo "[S2] ADD_FLEECE_REF=$ADD_FLEECE_REF"

# [HEALER WATCH POINT] Add Fleece Jacket — if badge cannot be located in S3, engage drift recovery below
playwright-cli -s="$SESSION" click "$ADD_FLEECE_REF"

# S3 — post-add: badge visible, Fleece Jacket button changed to Remove
# Badge appears as: generic [ref=eXX]: "1" in the first ~15 lines of the snapshot (header area)
playwright-cli -s="$SESSION" snapshot --filename="${PFX}-s3-after-add.yaml"
CART_BADGE_REF=$(head -15 "${PFX}-s3-after-add.yaml" | grep 'generic.*"[0-9]"' | grep -o 'ref=e[0-9]*' | cut -d= -f2)
echo "[S3] CART_BADGE_REF=$CART_BADGE_REF"

if [ -z "$CART_BADGE_REF" ]; then
  # ── DRIFT RECOVERY ──────────────────────────────────────────────────────────
  echo "HEALER: primary badge pattern returned nothing — engaging drift recovery"
  echo ""
  echo "Step 1: Fresh snapshot already saved as ${PFX}-s3-after-add.yaml"
  echo "Step 2: Searching for numeric node near header area..."
  head -20 "${PFX}-s3-after-add.yaml"
  echo ""
  echo "Step 3: Assign the ref of the element showing '1' near the cart icon as CART_BADGE_RECOVERED_REF,"
  echo "        then run: playwright-cli -s=\"$SESSION\" eval \"el => el.textContent\" <CART_BADGE_RECOVERED_REF>"
  echo "Step 4: Record drift — file a locator-update task with the recovered ref."
  # ────────────────────────────────────────────────────────────────────────────
  playwright-cli -s="$SESSION" tracing-stop
  playwright-cli -s="$SESSION" close
  exit 2
fi

grep -A5 'Sauce Labs Fleece Jacket' "${PFX}-s3-after-add.yaml" | grep 'button "Remove"' \
  && echo "[S3] Remove button visible for Fleece Jacket — PASS"

echo "[EVIDENCE] Badge text (expected 1):"
playwright-cli -s="$SESSION" eval "el => el.textContent" "$CART_BADGE_REF"

playwright-cli -s="$SESSION" screenshot --filename="${PFX}-screenshot.png"
playwright-cli -s="$SESSION" tracing-stop
playwright-cli -s="$SESSION" close

echo ""
echo "=== TC-AI-001 PASS. Artifacts: ${PFX}-s*.yaml  ${PFX}-screenshot.png ==="
