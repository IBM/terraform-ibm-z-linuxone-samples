#!/usr/bin/env bash
# =============================================================================
# reset.sh — Wipe generated credentials and certificates
#
# Usage:
#   bash reset.sh          ← removes .env, blanks secrets.yml, deletes certs
#   bash reset.sh --dry-run  ← shows what would be removed without touching anything
#
# What this script does:
#   1. Deletes cert files (cert.pem / key.pem / bundle.pem) for every host
#      directory found under files/certs/
#   2. Removes the .env file
#   3. Rewrites vars/secrets.yml with all credential values blanked out
#      (structure and comments are preserved)
#
# After running, re-populate setup.env and
# run  source setup.sh  to regenerate everything from scratch.
# =============================================================================

set -euo pipefail

CERTS_BASE="files/certs"
ENV_FILE=".env"
SECRETS_FILE="vars/secrets.yml"

# ── Colour helpers ────────────────────────────────────────────────────────────
_green()  { printf '\033[0;32m%s\033[0m\n' "$*"; }
_yellow() { printf '\033[0;33m%s\033[0m\n' "$*"; }
_red()    { printf '\033[0;31m%s\033[0m\n' "$*"; }
_bold()   { printf '\033[1m%s\033[0m\n'   "$*"; }

# ── Parse flags ───────────────────────────────────────────────────────────────
_dry=0
for arg in "${@:-}"; do
  [[ "$arg" == "--dry-run" ]] && _dry=1
done

[[ "$_dry" -eq 1 ]] && _yellow "DRY-RUN mode — nothing will be changed." && echo ""

# Helper: perform or announce an action
_do() {
  # $1 = description   $2+ = command
  local desc="$1"; shift
  if [[ "$_dry" -eq 1 ]]; then
    _yellow "  [dry-run] $desc"
  else
    "$@"
    _green "  ✔  $desc"
  fi
}

# =============================================================================
# Step 1 — Delete certificate files for each host in files/certs/
# =============================================================================
_bold "==> [1/3] Removing TLS certificate files..."

if [[ ! -d "$CERTS_BASE" ]]; then
  _yellow "    $CERTS_BASE not found — skipping."
else
  found=0
  for host_dir in "$CERTS_BASE"/*/; do
    # Skip if glob found no directories
    [[ -d "$host_dir" ]] || continue
    found=1
    host=$(basename "$host_dir")
    _bold "    Host: $host  ($host_dir)"

    for pem in cert.pem key.pem bundle.pem; do
      target="${host_dir}${pem}"
      if [[ -f "$target" ]]; then
        _do "Deleted  $target" rm -f "$target"
      else
        _yellow "    $target not found — skipping."
      fi
    done
  done

  [[ "$found" -eq 0 ]] && _yellow "    No host directories found under $CERTS_BASE — skipping."
fi

# =============================================================================
# Step 2 — Remove .env
# =============================================================================
_bold "==> [2/3] Removing $ENV_FILE..."

if [[ -f "$ENV_FILE" ]]; then
  _do "Deleted  $ENV_FILE" rm -f "$ENV_FILE"
else
  _yellow "    $ENV_FILE not found — skipping."
fi

# =============================================================================
# Step 3 — Blank all credential values in vars/secrets.yml
# =============================================================================
_bold "==> [3/3] Blanking credential values in $SECRETS_FILE..."

if [[ ! -f "$SECRETS_FILE" ]]; then
  _yellow "    $SECRETS_FILE not found — skipping."
else
  # Keys whose values should be blanked (exact YAML key names)
  BLANK_KEYS=(
    tfe_license
    tfe_encryption_password
    postgres_password
    redis_password
    minio_access_key
    minio_secret_key
    tfe_admin_password
    tfe_admin_email
    tfe_admin_username
  )

  if [[ "$_dry" -eq 1 ]]; then
    for key in "${BLANK_KEYS[@]}"; do
      _yellow "  [dry-run] Would blank: ${key}"
    done
  else
    # Use a temp file so we never leave secrets.yml half-written on error
    tmp=$(mktemp /tmp/secrets-reset-XXXXXX.yml)
    cp "$SECRETS_FILE" "$tmp"

    for key in "${BLANK_KEYS[@]}"; do
      # Replace:  key: "anything"  →  key: ""
      # Works for both quoted and unquoted values
      sed -i.bak "s|^${key}:.*|${key}: \"\"|" "$tmp"
    done
    rm -f "${tmp}.bak"

    mv "$tmp" "$SECRETS_FILE"
    _green "  ✔  Blanked ${#BLANK_KEYS[@]} credential keys in $SECRETS_FILE"
  fi
fi

# =============================================================================
# Summary
# =============================================================================
echo ""
_bold "════════════════════════════════════════════════════════════"
if [[ "$_dry" -eq 1 ]]; then
  _bold " DRY-RUN complete — no files were changed."
else
  _bold " Reset complete."
fi
_bold "════════════════════════════════════════════════════════════"
echo ""
echo "  Next step: update setup.env, then"
echo "  run:  source setup.sh"
echo "  to regenerate .env, vars/secrets.yml, and certificates."
echo ""
_bold "════════════════════════════════════════════════════════════"
