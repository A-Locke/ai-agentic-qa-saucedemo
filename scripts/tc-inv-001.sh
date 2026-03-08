#!/usr/bin/env bash
# TC-INV-001 — Sort Price Low to High
# Run from the project root: bash scripts/tc-inv-001.sh
set -euo pipefail

SESSION="tc-inv-001-sort-price-low-high"
PFX="tc-inv-001"

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

# S2 — inventory page (default sort: Name A to Z)
# Note: the sort dropdown has no accessible label — it appears as: combobox [ref=eXX]
playwright-cli -s="$SESSION" snapshot --filename="${PFX}-s2-inventory.yaml"
echo "[S2] $(grep 'Page URL' "${PFX}-s2-inventory.yaml")"
SORT_REF=$(grep 'combobox \[ref' "${PFX}-s2-inventory.yaml" | grep -o 'ref=e[0-9]*' | cut -d= -f2)
echo "[S2] SORT_REF=$SORT_REF  current: $(grep 'option.*\[selected\]' "${PFX}-s2-inventory.yaml")"

playwright-cli -s="$SESSION" select "$SORT_REF" "lohi"

# S3 — inventory sorted Price low to high
playwright-cli -s="$SESSION" snapshot --filename="${PFX}-s3-sorted.yaml"
echo "[S3] $(grep 'option.*\[selected\]' "${PFX}-s3-sorted.yaml")"
# Prices appear as: generic [ref=eXX]: $7.99
FIRST_PRICE_REF=$(grep 'generic.*\$[0-9]' "${PFX}-s3-sorted.yaml" | head -1 | grep -o 'ref=e[0-9]*' | cut -d= -f2)
LAST_PRICE_REF=$(grep  'generic.*\$[0-9]' "${PFX}-s3-sorted.yaml" | tail -1 | grep -o 'ref=e[0-9]*' | cut -d= -f2)
echo "[S3] FIRST_PRICE_REF=$FIRST_PRICE_REF  LAST_PRICE_REF=$LAST_PRICE_REF"

echo "[EVIDENCE] First price (expected \$7.99):"
playwright-cli -s="$SESSION" eval "el => el.textContent" "$FIRST_PRICE_REF"

echo "[EVIDENCE] Last price (expected \$49.99):"
playwright-cli -s="$SESSION" eval "el => el.textContent" "$LAST_PRICE_REF"

playwright-cli -s="$SESSION" screenshot --filename="${PFX}-screenshot.png"
playwright-cli -s="$SESSION" tracing-stop
playwright-cli -s="$SESSION" close

echo ""
echo "=== TC-INV-001 PASS. Expected: first=\$7.99  last=\$49.99. Artifacts: ${PFX}-s*.yaml  ${PFX}-screenshot.png ==="
