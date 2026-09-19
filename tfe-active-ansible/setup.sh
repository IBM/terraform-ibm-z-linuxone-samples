#!/usr/bin/env bash
# =============================================================================
# setup.sh — Bootstrap the TFE Active-Active Ansible control environment
#
# Usage:
#   source setup.sh     ← recommended: activates the venv in your shell
#   bash   setup.sh     ← builds/updates the venv but does NOT activate it
#
# What this script does:
#   0. Loads configuration from setup.env and writes .env + vars/secrets.yml
#   1. Locates a Python 3.9+ interpreter
#   2. Creates (or reuses) the .ansible-env virtual environment
#   3. Upgrades pip and installs requirements.txt
#   4. Activates the virtual environment (only when sourced)
#   5. Reads inventory/hosts.yml, creates files/certs/<host>/ for every active
#      host in the tfe group. For each host:
#        • Resolves the ansible_host env-var name from the inventory line
#        • Generates a self-signed cert/key using that hostname as CN + SAN
#        • Copies cert.pem → bundle.pem
#   6. Prints next-step instructions
#
# To update .env / secrets.yml / certs: edit setup.env and re-run source setup.sh.
# =============================================================================

# ── Script directory resolution ──────────────────────────────────────────────
if [[ -n "${BASH_SOURCE[0]+x}" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
elif [[ -n "${(%):-%x}" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${(%):-%x}")" && pwd)"
else
  SCRIPT_DIR="$(pwd)"
fi

# ── Load setup.env configuration ─────────────────────────────────────────────
SETUP_ENV_FILE="${SCRIPT_DIR}/setup.env"
if [[ -f "$SETUP_ENV_FILE" ]]; then
  # shellcheck source=/dev/null
  source "$SETUP_ENV_FILE"
else
  printf '\033[0;31mERROR: setup.env not found at %s\033[0m\n' "$SETUP_ENV_FILE" >&2
  printf '\033[0;31m       Please create setup.env and configure your variables.\033[0m\n' >&2
  return 1 2>/dev/null || exit 1
fi

# ── Detect whether the script is being sourced (must happen before set -e) ───
_sourced=0
if [[ -n "${BASH_SOURCE[0]+x}" ]]; then
  [[ "${BASH_SOURCE[0]}" != "$0" ]] && _sourced=1
elif [[ -n "${ZSH_EVAL_CONTEXT+x}" ]]; then
  [[ "${ZSH_EVAL_CONTEXT}" == *":file"* ]] && _sourced=1
fi

# ── zsh/bash portable regex capture helper ───────────────────────────────────
# Usage: after [[ str =~ pattern ]], call _cap N to get the Nth capture group.
# bash stores captures in BASH_REMATCH[N] (0-indexed; [0]=full match).
# zsh  stores captures in match[N]        (1-indexed; [1]=first group).
_cap() {
  if [[ -n "${ZSH_VERSION:-}" ]]; then
    echo "${match[$1]}"
  else
    echo "${BASH_REMATCH[$1]}"
  fi
}

# ── Save the caller's shell options so we can restore them when sourced ───────
# set -euo pipefail is safe inside an executed script but kills the terminal
# if used during `source`. We track only the specific options we change so
# we can restore them cleanly in both bash and zsh.
if [[ "$_sourced" -eq 1 ]]; then
  # Record which options were already set before we change them
  _had_errexit=0;  [[ -o errexit   ]] 2>/dev/null && _had_errexit=1
  _had_nounset=0;  [[ -o nounset   ]] 2>/dev/null && _had_nounset=1
  _had_pipefail=0; [[ -o pipefail  ]] 2>/dev/null && _had_pipefail=1
fi

set -euo pipefail

# ── Abort helper — return when sourced, exit when executed ────────────────────
_abort() {
  if [[ "$_sourced" -eq 1 ]]; then
    _restore_opts
    return 1
  else
    exit 1
  fi
}

# ── Restore only the shell options this script turned on ─────────────────────
_restore_opts() {
  if [[ "$_sourced" -eq 1 ]]; then
    [[ "$_had_errexit"  -eq 0 ]] && set +e  2>/dev/null || true
    [[ "$_had_nounset"  -eq 0 ]] && set +u  2>/dev/null || true
    [[ "$_had_pipefail" -eq 0 ]] && set +o pipefail 2>/dev/null || true
  fi
}

VENV_DIR=".ansible-active-env"
REQ_FILE="requirements.txt"
ENV_FILE=".env"
SECRETS_FILE="vars/secrets.yml"

# ── Colour helpers ────────────────────────────────────────────────────────────
_green()  { printf '\033[0;32m%s\033[0m\n' "$*"; }
_yellow() { printf '\033[0;33m%s\033[0m\n' "$*"; }
_red()    { printf '\033[0;31m%s\033[0m\n' "$*"; }
_bold()   { printf '\033[1m%s\033[0m\n'   "$*"; }

# ── Helper: check whether every required configuration variable is filled in ────
_config_complete() {
  local missing=()
  [[ -z "${VM1_ANSIBLE_HOST:-}"      ]] && missing+=("VM1_ANSIBLE_HOST")
  [[ -z "${VM1_ANSIBLE_PASSWORD:-}"  ]] && missing+=("VM1_ANSIBLE_PASSWORD")
  [[ -z "${SERVICE_ANSIBLE_HOST:-}"  ]] && missing+=("SERVICE_ANSIBLE_HOST")
  [[ -z "${SERVICE_ANSIBLE_PASSWORD:-}" ]] && missing+=("SERVICE_ANSIBLE_PASSWORD")
  [[ -z "${TFE_LICENSE:-}"           ]] && missing+=("TFE_LICENSE")
  [[ -z "${TFE_ENCRYPTION_PASSWORD:-}" ]] && missing+=("TFE_ENCRYPTION_PASSWORD")
  [[ -z "${POSTGRES_PASSWORD:-}"     ]] && missing+=("POSTGRES_PASSWORD")
  [[ -z "${REDIS_PASSWORD:-}"        ]] && missing+=("REDIS_PASSWORD")
  [[ -z "${MINIO_ACCESS_KEY:-}"      ]] && missing+=("MINIO_ACCESS_KEY")
  [[ -z "${MINIO_SECRET_KEY:-}"      ]] && missing+=("MINIO_SECRET_KEY")
  [[ -z "${TFE_ADMIN_PASSWORD:-}"    ]] && missing+=("TFE_ADMIN_PASSWORD")

  if [[ "${#missing[@]}" -gt 0 ]]; then
    _red "ERROR: The following required configuration fields are missing or empty in setup.env:"
    for f in "${missing[@]}"; do
      _red "       • $f"
    done
    _red "       Please fill in all required fields in setup.env and re-run: source setup.sh"
    return 1
  fi
  return 0
}

# =============================================================================
# Step 0 — Validate setup.env & Write .env and vars/secrets.yml
# =============================================================================
_bold "==> [0/5] Validating setup.env and writing configuration files..."

if ! _config_complete; then
  _abort; return $? 2>/dev/null || exit 1
fi

_write_env() {
  mkdir -p "$(dirname "$ENV_FILE")"
  cat > "$ENV_FILE" <<EOF
# Generated by setup.sh from setup.env — do NOT commit this file.
# Edit setup.env and re-run 'source setup.sh' to regenerate.

# ── TFE Node 1 (VM1 · RHEL · s390x) ─────────────────────────────────────────
VM1_ANSIBLE_HOST=${VM1_ANSIBLE_HOST}
VM1_ANSIBLE_USER=${VM1_ANSIBLE_USER}
VM1_ANSIBLE_PASSWORD=${VM1_ANSIBLE_PASSWORD}

# ── TFE Node 2 (VM2 · RHEL · s390x) — uncomment when tfe02 is active ────────
# VM2_ANSIBLE_HOST=${VM2_ANSIBLE_HOST:-}
# VM2_ANSIBLE_USER=${VM2_ANSIBLE_USER:-root}
# VM2_ANSIBLE_PASSWORD=${VM2_ANSIBLE_PASSWORD:-}

# ── External Services Node (services01 · RHEL · x86_64) ──────────────────────
SERVICE_ANSIBLE_HOST=${SERVICE_ANSIBLE_HOST}
SERVICE_ANSIBLE_USER=${SERVICE_ANSIBLE_USER}
SERVICE_ANSIBLE_PASSWORD=${SERVICE_ANSIBLE_PASSWORD}
EOF
  _green "    Written: $ENV_FILE"
}

_write_secrets() {
  mkdir -p "$(dirname "$SECRETS_FILE")"
  cat > "$SECRETS_FILE" <<EOF
---
# Generated by setup.sh — encrypt with 'ansible-vault encrypt vars/secrets.yml'
# before committing. Never store plaintext credentials in source control.

# ==========================================================
# TFE LICENSE AND EXTERNAL SERVICES CREDS
# ==========================================================
tfe_license: "${TFE_LICENSE}"

tfe_encryption_password: "${TFE_ENCRYPTION_PASSWORD}"

postgres_password: "${POSTGRES_PASSWORD}"

redis_password: "${REDIS_PASSWORD}"

minio_access_key: "${MINIO_ACCESS_KEY}"

minio_secret_key: "${MINIO_SECRET_KEY}"

# ==========================================================
# TFE Initial Admin User
# ==========================================================
tfe_admin_username: "${TFE_ADMIN_USERNAME}"
tfe_admin_email: "${TFE_ADMIN_EMAIL}"
tfe_admin_password: "${TFE_ADMIN_PASSWORD}"
EOF
  _green "    Written: $SECRETS_FILE"
}

_write_env
_write_secrets

# =============================================================================
# Step 1 — Locate Python 3.9+
# =============================================================================
_bold "==> [1/5] Locating Python 3.9+ interpreter..."

PYTHON_BIN=""
for candidate in python3.14 python3.13 python3.12 python3.11 python3.10 python3.9 python3; do
  if command -v "$candidate" &>/dev/null; then
    version=$("$candidate" -c 'import sys; print("%d.%d" % sys.version_info[:2])')
    major="${version%%.*}"
    minor="${version##*.}"
    if [[ "$major" -ge 3 && "$minor" -ge 9 ]]; then
      PYTHON_BIN=$(command -v "$candidate")
      _green "    Found: $PYTHON_BIN ($version)"
      break
    fi
  fi
done

if [[ -z "$PYTHON_BIN" ]]; then
  _red "ERROR: Python 3.9 or newer is required but was not found in PATH."
  _red "       Install Python 3.9+ and re-run this script."
  _abort; return $? 2>/dev/null || exit 1
fi

# =============================================================================
# Step 2 — Create virtual environment
# =============================================================================
_bold "==> [2/5] Setting up virtual environment in ./$VENV_DIR ..."

if [[ -d "$VENV_DIR" ]]; then
  _yellow "    Virtual environment already exists — skipping creation."
else
  "$PYTHON_BIN" -m venv "$VENV_DIR"
  _green "    Created: $VENV_DIR"
fi

VENV_PYTHON="$VENV_DIR/bin/python"
VENV_PIP="$VENV_DIR/bin/pip"

# =============================================================================
# Step 3 — Upgrade pip
# =============================================================================
_bold "==> [3/5] Upgrading pip..."
"$VENV_PYTHON" -m pip install --quiet --upgrade pip
_green "    pip upgraded."

# =============================================================================
# Step 4 — Install dependencies
# =============================================================================
_bold "==> [4/5] Installing dependencies from $REQ_FILE ..."

if [[ ! -f "$REQ_FILE" ]]; then
  _red "ERROR: $REQ_FILE not found. Cannot install dependencies."
  _abort; return $? 2>/dev/null || exit 1
fi

"$VENV_PIP" install --quiet -r "$REQ_FILE"
_green "    Dependencies installed."

# =============================================================================
# Step 4 (activation) — Activate venv (only when sourced)
# =============================================================================
if [[ "$_sourced" -eq 1 ]]; then
  # Export .env variables into the current shell session.
  # Read line-by-line instead of `source .env` so comment lines and
  # blank lines never trigger set -u / set -e errors.
  if [[ -f "$ENV_FILE" ]]; then
    while IFS= read -r _envline || [[ -n "$_envline" ]]; do
      # Skip blank lines and comment lines
      [[ -z "$_envline" || "$_envline" =~ ^[[:space:]]*# ]] && continue
      # Only process lines that look like KEY=VALUE
      [[ "$_envline" =~ ^[[:space:]]*([A-Za-z_][A-Za-z0-9_]*)= ]] || continue
      export "$_envline" 2>/dev/null || true
    done < "$ENV_FILE"
    _green "    Exported variables from $ENV_FILE into shell."
  fi

  # shellcheck source=/dev/null
  source "$VENV_DIR/bin/activate"
  _green ""
  _green "✔  Virtual environment activated."
  _green "   Python : $(python --version)"
  _green "   Ansible: $(ansible --version | head -1)"
fi

# =============================================================================
# Step 5 — Generate self-signed TLS certificates for every active tfe host
#
# Reads inventory/hosts.yml and finds every non-commented host in the `tfe`
# group.  For each host it:
#   1. Extracts the env-var name from the ansible_host Jinja2 lookup line,
#      e.g. "{{ lookup('env', 'VM1_ANSIBLE_HOST') }}" → VM1_ANSIBLE_HOST
#   2. Resolves that env var to get the actual hostname / IP
#   3. Creates files/certs/<inventory_hostname>/ (e.g. tfe01, tfe02)
#   4. Generates a self-signed RSA-4096 cert valid for 365 days, with the
#      hostname as CN and as a DNS SAN (+ IP:127.0.0.1)
#   5. Copies cert.pem → bundle.pem
# =============================================================================
_bold "==> [5/5] Generating TLS certificates for tfe hosts..."

# Portable indirect variable expansion: bash uses ${!name}, zsh uses ${(P)name}
_deref() {
  if [[ -n "${ZSH_VERSION:-}" ]]; then
    echo "${(P)1}"
  else
    echo "${!1}"
  fi
}

_gen_certs() {
  local hosts_file="inventory/hosts.yml"
  if [[ ! -f "$hosts_file" ]]; then
    _yellow "    WARNING: $hosts_file not found — skipping cert generation."
    return
  fi

  # Three-state machine:
  #   in_tfe=0  — scanning for the `tfe:` group key
  #   in_tfe=1  — inside `tfe:`, waiting for its `hosts:` sub-key
  #   in_tfe=2  — inside `tfe: > hosts:`, collecting host entries
  #   in_tfe=3  — done (left the tfe group), skip the rest of the file
  local in_tfe=0
  local hosts_indent=""
  local current_host=""
  # Regex stored in a variable so single-quote literals work in both
  # bash and zsh (zsh rejects \' inside inline [[ =~ ]] patterns).
  local _re_lookup
  _re_lookup="lookup\\('env', *'([A-Za-z0-9_]+)'\\)"

  while IFS= read -r line; do
    # ── Done: already processed the tfe group ────────────────────────────────
    [[ "$in_tfe" -eq 3 ]] && break

    # ── State 0: look for the `tfe:` group key ───────────────────────────────
    if [[ "$in_tfe" -eq 0 ]]; then
      if [[ "$line" =~ ^[[:space:]]*tfe:[[:space:]]*$ ]]; then
        in_tfe=1
      fi
      continue
    fi

    # ── State 1: inside `tfe:`, wait for its `hosts:` sub-key ────────────────
    if [[ "$in_tfe" -eq 1 ]]; then
      if [[ "$line" =~ ^([[:space:]]*)hosts:[[:space:]]*$ ]]; then
        in_tfe=2
        hosts_indent="$(_cap 1)"
      elif [[ "$line" =~ ^[[:space:]]*[a-zA-Z] && ! "$line" =~ ^[[:space:]]*hosts: ]]; then
        # A new top-level or sibling key before `hosts:` — tfe block is done
        in_tfe=3
      fi
      continue
    fi

    # ── State 2: inside `tfe: > hosts:` ──────────────────────────────────────
    # A non-blank, non-comment line indented ≤ hosts_indent means we left the block
    local line_trimmed="${line#"${line%%[! ]*}"}"
    local line_indent="${line%"$line_trimmed"}"
    if [[ -n "$line" && ! "$line" =~ ^[[:space:]]*# ]]; then
      if [[ "${#line_indent}" -le "${#hosts_indent}" ]]; then
        in_tfe=3
        break
      fi
    fi

    # Skip comment and blank lines
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ -z "${line// }" ]] && continue

    # Host name line — e.g. "        tfe01:"
    if [[ "$line" =~ ^[[:space:]]+([a-zA-Z0-9_-]+):[[:space:]]*$ ]]; then
      current_host="$(_cap 1)"
      continue
    fi

    # ansible_host lookup line — resolve the env var and generate the cert
    if [[ -n "$current_host" && "$line" =~ $_re_lookup ]]; then
      local env_var_name
      env_var_name="$(_cap 1)"
      local tfe_hostname
      tfe_hostname="$(_deref "$env_var_name")"

      if [[ -z "$tfe_hostname" ]]; then
        _yellow "    SKIP $current_host: env var \$$env_var_name is not set."
        current_host=""
        continue
      fi

      local cert_dir="files/certs/${current_host}"
      mkdir -p "$cert_dir"

      if [[ -f "${cert_dir}/cert.pem" && -f "${cert_dir}/key.pem" ]]; then
        _yellow "    SKIP $current_host ($tfe_hostname): cert already exists — delete to regenerate."
        current_host=""
        continue
      fi

      _green "    Generating cert for $current_host  CN=${tfe_hostname}  → ${cert_dir}/"
      openssl req -x509 -newkey rsa:4096 -sha256 -days 365 -nodes \
        -keyout "${cert_dir}/key.pem" \
        -out    "${cert_dir}/cert.pem" \
        -subj   "/CN=${tfe_hostname}" \
        -addext "subjectAltName=DNS:${tfe_hostname},IP:127.0.0.1" \
        2>/dev/null
      cp "${cert_dir}/cert.pem" "${cert_dir}/bundle.pem"
      _green "    Done: cert.pem  key.pem  bundle.pem"
      current_host=""
    fi
  done < "$hosts_file"
}

# Load .env into the current process before generating certs so that
# _deref() can resolve hostnames whether the script is sourced or executed.
if [[ -f "$ENV_FILE" ]]; then
  while IFS= read -r _envline || [[ -n "$_envline" ]]; do
    [[ -z "$_envline" || "$_envline" =~ ^[[:space:]]*# ]] && continue
    [[ "$_envline" =~ ^[[:space:]]*([A-Za-z_][A-Za-z0-9_]*)= ]] || continue
    export "$_envline" 2>/dev/null || true
  done < "$ENV_FILE"
fi

_gen_certs

# =============================================================================
# Summary banner
# =============================================================================
echo ""
_bold "════════════════════════════════════════════════════════════"
_bold " TFE Active-Active — environment ready"
_bold "════════════════════════════════════════════════════════════"
if [[ "$_sourced" -eq 0 ]]; then
  echo ""
  _yellow "  NOTE: Run with 'source' to activate the venv in your shell:"
  _yellow "        source setup.sh"
  echo ""
fi
echo "  Next steps:"
echo ""
echo "  1. If you haven't filled in setup.env yet, edit setup.env and"
echo "     re-run:  source setup.sh"
echo "     .env and vars/secrets.yml are always regenerated on every run."
echo ""
echo "  2. Confirm TLS certificates were generated (check output above)."
echo ""
echo "  3. Run the full deployment:"
echo "      ansible-playbook site.yml"
echo ""
_bold "════════════════════════════════════════════════════════════"

# ── Restore original shell options (no-op when executed via bash setup.sh) ────
_restore_opts
