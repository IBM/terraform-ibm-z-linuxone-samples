# Terraform Enterprise — Active-Active Ansible Deployment

Ansible automation to deploy Terraform Enterprise (TFE) in **active-active** mode on
RHEL/s390x using Podman, backed by external PostgreSQL, Redis, and MinIO services
running on a separate x86_64 VM.

```
Users / Clients
      │ HTTPS :443
      ▼
   HAProxy  (VM1 · s390x)
      │
      ├──► TFE Instance 1  :8443  (VM1 · s390x · Podman)
      └──► TFE Instance 2  :8443  (VM2 · s390x · Podman)  ← planned
                │
                ▼
     External Services VM  (x86_64)
     ├── PostgreSQL  :5432
     ├── Redis       :6379
     └── MinIO       :9000 / :9001
```

---

## Prerequisites

| Requirement | Details |
|---|---|
| Control node OS | macOS or Linux with Python 3.9+ |
| Ansible | 2.14+ — installed automatically by `setup.sh` |
| TFE image archive | `terraform-for-z-2-0-5` transferred to the TFE VM at `/tmp/` |
| TFE VM (VM1) | RHEL, s390x architecture |
| Services VM (VM2) | RHEL, x86_64 — PostgreSQL, Redis, and MinIO already running |
| TLS certificates | `cert.pem`, `key.pem`, `bundle.pem` for each TFE host |
| SSH/password access | Password-based SSH access to both VMs |

---

## Getting Started

There are two ways to set up the control environment. Pick one.

| | Automated | Manual |
|---|---|---|
| **What you edit** | `setup.env` configuration file | `.env` + `vars/secrets.yml` by hand |
| **What gets generated** | `.env` and `vars/secrets.yml` are written for you | You create and edit both files yourself |
| **Best for** | First-time setup, repeatable onboarding | Existing environments, CI, Ansible Vault workflows |

---

## Option A — Automated Setup (recommended for new users)

Everything is driven from a separate configuration file: [`setup.env`](setup.env).
Fill it in once, run one command, and [`setup.sh`](setup.sh) takes care of the rest.

### 1. Clone the repository

```bash
git clone https://github.com/IBM/terraform-ibm-z-linuxone-samples.git
```

### 2. Change directory to `tfe-active-ansible`

```bash
cd terraform-ibm-z-linuxone-samples/tfe-active-ansible
```

### 3. Create and configure `setup.env`

Create or open [`setup.env`](setup.env) and configure your variables:

```bash
touch setup.env
```

```bash
# ── TFE Node 1 (VM1 · RHEL · s390x) — active ────────────────────────────────
VM1_ANSIBLE_HOST="tfe.domain.com"       # FQDN of the TFE VM1
VM1_ANSIBLE_USER="root"
VM1_ANSIBLE_PASSWORD="your-ssh-password"

# ── TFE Node 2 (VM2 · RHEL · s390x) — future active-active node ─────────────
# Uncomment and populate when tfe02 is added to inventory/hosts.yml
# VM2_ANSIBLE_HOST=""                 # IP or FQDN of the TFE VM2
# VM2_ANSIBLE_USER=""             # SSH user for VM2
# VM2_ANSIBLE_PASSWORD=""             # SSH password for VM2

# ── External Services Node (services01 · RHEL · x86_64) ──────────────────────
SERVICE_ANSIBLE_HOST="services.domain.com"   # FQDN of the services VM
SERVICE_ANSIBLE_USER="root"
SERVICE_ANSIBLE_PASSWORD="your-ssh-password"

# ── TFE License & Encryption ─────────────────────────────────────────────────
TFE_LICENSE="02MV4UU43BK5..."         # Your TFE license string
TFE_ENCRYPTION_PASSWORD="$(openssl rand -base64 32)"

# ── External Service Credentials ─────────────────────────────────────────────
POSTGRES_PASSWORD="strong-pg-password"
REDIS_PASSWORD="strong-redis-password"
MINIO_ACCESS_KEY="minio-access-key"
MINIO_SECRET_KEY="strong-minio-secret"

# ── TFE Initial Admin User ────────────────────────────────────────────────────
TFE_ADMIN_USERNAME="admin"
TFE_ADMIN_EMAIL="admin@example.com"
TFE_ADMIN_PASSWORD="Admin@StrongPass1"
```

> `setup.env` is listed in `.gitignore` so your credentials remain secure and won't be committed to source control.

### 4. Run `setup.sh`

```bash
source setup.sh
```

This single command will:

| Step | What happens |
|---|---|
| `[0/5]` | Loads `setup.env` and **writes `.env`** and **`vars/secrets.yml`** automatically |
| `[1/5]` | Locates Python 3.9+ on your system |
| `[2/5]` | Creates the `.ansible-active-env/` virtual environment (skips if it already exists) |
| `[3/5]` | Upgrades `pip` inside the venv |
| `[4/5]` | Installs `ansible` and all dependencies from `requirements.txt` |
| Activate | Sources `.env` into the shell session and activates the venv |
| `[5/5]` | Parses `inventory/hosts.yml`, creates `files/certs/<host>/` for every active host in the `tfe:` group, and generates self-signed TLS certificates |

> **`source` vs `bash`:** Use `source setup.sh` (or `. setup.sh`) so the venv
> activation and exported variables persist in your terminal. `bash setup.sh` builds
> everything but the venv stays inactive — use that form in CI only.

If any required field is missing or empty, the script prints an error listing all missing fields and terminates execution immediately.

### 5. Re-running after changes

Every run of `source setup.sh` **always regenerates** `.env` and `vars/secrets.yml`
from the current `setup.env` values. There is no flag needed — just edit `setup.env` and
re-run:

```bash
source setup.sh
```

### 6. Verify certificate output

Step `[5/5]` reports the result for every host and every file. There are three possible
outcomes per file:

| Output | Meaning |
|---|---|
| ✅ `cert.pem ← /your/path` (green) | File was copied successfully |
| ⚠ `cert.pem already exists — skipping` (yellow) | File is already in place; no action needed |
| ⚠ `cert.pem MISSING — set TFE01_CERT` (yellow) | Path variable is empty or points to a non-existent file |

If any file shows `MISSING`, fill in the corresponding variable in the USER CONFIG block
and re-run `source setup.sh`.

**Adding a second TFE node:**
Uncomment the `tfe02` block in [`inventory/hosts.yml`](inventory/hosts.yml) and add the
corresponding cert variables to the USER CONFIG block:

```bash
TFE02_CERT="/path/to/tfe02/cert.pem"
TFE02_KEY="/path/to/tfe02/key.pem"
TFE02_BUNDLE="/path/to/tfe02/bundle.pem"
```

The script automatically derives variable names from hostnames — `tfe02` maps to
`TFE02_CERT` / `TFE02_KEY` / `TFE02_BUNDLE`, `tfe-node1` maps to `TFE_NODE1_CERT`,
and so on.

### A5 — Deploy

```bash
ansible-playbook site.yml
```

---

## Option B — Manual Setup

Use this path if you prefer to manage `.env` and `vars/secrets.yml` yourself, are
working in an existing environment, or are using Ansible Vault to encrypt secrets.

### B1 — Activate the virtual environment

```bash
source .ansible-active-env/bin/activate
```

If the venv does not exist yet, create it first:

```bash
python3 -m venv .ansible-active-env
source .ansible-active-env/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
```

### B2 — Create and populate `.env`

```bash
cp .env.example .env
```

Edit `.env` and fill in the SSH connection details for both VMs:

```dotenv
# ── TFE Node (VM1 · RHEL · s390x) ────────────────────────────────────────────
VM1_ANSIBLE_HOST=<ip-or-hostname-of-tfe-vm>
VM1_ANSIBLE_USER=root
VM1_ANSIBLE_PASSWORD=<ssh-password>

# ── External Services Node (VM2 · RHEL · x86_64) ─────────────────────────────
SERVICE_ANSIBLE_HOST=<ip-or-hostname-of-services-vm>
SERVICE_ANSIBLE_USER=root
SERVICE_ANSIBLE_PASSWORD=<ssh-password>
```

Export the variables into your shell session:

```bash
set -a && source .env && set +a
```

### B3 — Populate `vars/secrets.yml`

Edit [`vars/secrets.yml`](vars/secrets.yml) and replace every placeholder:

```yaml
# ── TFE License & Encryption ─────────────────────────────────────────
tfe_license: "<your-tfe-license-string>"
tfe_encryption_password: "<openssl rand -base64 32>"

# ── External Services ────────────────────────────────────────────────
postgres_password: "<postgresql-password>"
redis_password: "<redis-password>"
minio_access_key: "<minio-access-key>"
minio_secret_key: "<minio-secret-key>"

# ── Initial Admin User ───────────────────────────────────────────────
tfe_admin_username: "admin"
tfe_admin_email: "admin@example.com"
tfe_admin_password: "<strong-admin-password>"
```

> **Security:** Encrypt this file before pushing to source control:
> ```bash
> ansible-vault encrypt vars/secrets.yml
> ```
> Then pass `--ask-vault-pass` (or `--vault-password-file`) to every
> `ansible-playbook` invocation.

### B4 — Place TLS certificates

For each TFE host in the inventory, create a subdirectory named after the
**inventory hostname** and place three PEM files inside manually:

```
files/certs/
└── tfe01/
    ├── cert.pem      # TLS certificate
    ├── key.pem       # TLS private key
    └── bundle.pem    # CA / intermediate chain
```

The hostname (`tfe01`) must match exactly what appears under the `tfe:` group in
[`inventory/hosts.yml`](inventory/hosts.yml).

> **Tip:** If you later switch to Option A, set `TFE01_CERT`, `TFE01_KEY`, and
> `TFE01_BUNDLE` in the USER CONFIG block and run `source setup.sh` — the
> script will copy the files you pointed to on the next run.

### B5 — (Optional) Review group variables

Open [`inventory/group_vars/tfe.yml`](inventory/group_vars/tfe.yml) to adjust defaults:

| Variable | Default | Description |
|---|---|---|
| `tfe_version` | `2.0.5` | TFE version string |
| `tfe_image_file` | `/tmp/terraform-for-z-2-0-5` | Path to the OCI image archive on the TFE host |
| `tfe_image` | `localhost/terraform-enterprise:2.0.5-s390x` | Local Podman image tag after load |
| `tfe_operational_mode` | `active-active` | TFE operational mode |
| `tfe_install_dir` | `/opt/terraform-enterprise` | Installation directory on the TFE host |
| `postgres_port` | `5432` | PostgreSQL port on the services VM |
| `redis_port` | `6379` | Redis port on the services VM |
| `minio_port` | `9000` | MinIO API port on the services VM |
| `minio_bucket` | `terraform-enterprise` | S3 bucket name in MinIO |
| `tfe_https_port` | `8443` | HTTPS port TFE listens on inside the container |

### B6 — Deploy

```bash
ansible-playbook site.yml
```

---

## Deployment Pipeline

`site.yml` runs these playbooks in order. Both setup paths use the same pipeline.

| # | Playbook | What it does |
|---|---|---|
| 1 | [`precheck.yml`](playbooks/precheck.yml) | Validates s390x architecture, checks Podman, verifies connectivity to PostgreSQL / Redis / MinIO, checks disk space |
| 2 | [`prepare.yml`](playbooks/prepare.yml) | Installs packages (podman, haproxy, rsyslog), creates directories and Podman volume, deploys HAProxy config, opens firewall ports |
| 3 | [`load-image.yml`](playbooks/load-image.yml) | Loads the TFE OCI archive into Podman, tags it with the expected image name, validates s390x architecture |
| 4 | [`configure.yml`](playbooks/configure.yml) | Copies TLS certificates, renders the Podman Kubernetes pod manifest from the Jinja2 template |
| 5 | [`deploy.yml`](playbooks/deploy.yml) | Starts the TFE pod via `podman kube play`, waits up to 30 min for readiness (Vault HA lock on s390x takes ~15 min) |
| 6 | [`validate.yml`](playbooks/validate.yml) | Confirms containers running, checks HTTPS endpoints directly and via HAProxy, verifies all service connectivity |
| 7 | [`admin-user.yml`](playbooks/admin-user.yml) | Retrieves the IACT token and creates the initial admin user via the TFE API |

---

## Running Individual Playbooks

Any playbook can be run independently when needed:

```bash
# Pre-flight checks only
ansible-playbook playbooks/precheck.yml

# Re-deploy without re-running the full pipeline
ansible-playbook playbooks/deploy.yml

# Re-create the initial admin user
ansible-playbook playbooks/admin-user.yml

# Validate a running installation
ansible-playbook playbooks/validate.yml
```

---

## Teardown

To completely remove TFE and reset the host to a clean state:

```bash
ansible-playbook teardown.yml
```

This will:
- Wipe Vault storage from PostgreSQL (allows a clean re-bootstrap on the next deploy)
- Stop and remove the TFE Podman pod and all volumes
- Remove the TFE OCI image from Podman
- Delete the installation directory (`/opt/terraform-enterprise`)
- Remove HAProxy and rsyslog configuration files
- Close all firewall ports opened during deployment
- Uninstall Podman

---

## Project Structure

```
.
├── setup.env                        # Setup configuration and credentials
├── setup.sh                         # Bootstrap script — venv, .env, secrets.yml, certs
├── requirements.txt                 # Pip dependencies (ansible + transitive)
├── .env.example                     # Template for .env (manual path)
├── site.yml                         # Full deployment pipeline
├── teardown.yml                     # Full teardown
├── ansible.cfg                      # Ansible configuration (inventory path)
│
├── inventory/
│   ├── hosts.yml                    # Host definitions (reads from .env variables)
│   ├── group_vars/
│   │   └── tfe.yml                  # TFE group variables (ports, image, paths)
│   └── host_vars/
│       ├── tfe01.yml                # Per-host overrides for tfe01
│       └── tfe02.yml                # Per-host overrides for tfe02 (future)
│
├── vars/
│   └── secrets.yml                  # Credentials — keep out of source control
│
├── files/
│   └── certs/
│       └── tfe01/                   # TLS certs per inventory hostname
│           ├── cert.pem
│           ├── key.pem
│           └── bundle.pem
│
├── templates/
│   ├── compose.yml.j2               # Podman Kubernetes pod manifest
│   ├── haproxy.cfg.j2               # HAProxy load balancer config
│   ├── tfe.env.j2                   # TFE environment file (reserved)
│   └── rsyslog-haproxy.conf.j2      # rsyslog config for HAProxy logs
│
└── playbooks/
    ├── precheck.yml
    ├── prepare.yml
    ├── load-image.yml
    ├── configure.yml
    ├── deploy.yml
    ├── validate.yml
    └── admin-user.yml
```

---

## Environment Variables Reference

All SSH connection credentials are read from environment variables so they are never
stored in the repository. [`inventory/hosts.yml`](inventory/hosts.yml) uses
`lookup('env', ...)` to read them at runtime.

| Variable | Set by | Used in | Description |
|---|---|---|---|
| `VM1_ANSIBLE_HOST` | `setup.env` / `.env` | `inventory/hosts.yml` | IP or FQDN of the TFE node (VM1) |
| `VM1_ANSIBLE_USER` | `setup.env` / `.env` | `inventory/hosts.yml` | SSH user for VM1 |
| `VM1_ANSIBLE_PASSWORD` | `setup.env` / `.env` | `inventory/hosts.yml` | SSH password for VM1 |
| `SERVICE_ANSIBLE_HOST` | `setup.env` / `.env` | `inventory/hosts.yml`, `group_vars/tfe.yml` | IP or FQDN of the services node (VM2) |
| `SERVICE_ANSIBLE_USER` | `setup.env` / `.env` | `inventory/hosts.yml` | SSH user for VM2 |
| `SERVICE_ANSIBLE_PASSWORD` | `setup.env` / `.env` | `inventory/hosts.yml` | SSH password for VM2 |

---

## Adding a Second TFE Node (Active-Active)

The second node (`tfe02`) is pre-stubbed in the inventory and HAProxy config. To enable it:

1. Uncomment the `tfe02` block in [`inventory/hosts.yml`](inventory/hosts.yml).
2. Add `files/certs/tfe02/cert.pem`, `key.pem`, `bundle.pem`.
3. Uncomment the `tfe02` server line in [`templates/haproxy.cfg.j2`](templates/haproxy.cfg.j2) and set its IP.
4. Change `tfe_vault_bind_address` in [`inventory/group_vars/tfe.yml`](inventory/group_vars/tfe.yml) from `127.0.0.1` to `0.0.0.0` so Vault's cluster port is reachable between nodes.
5. Run `ansible-playbook site.yml` — the existing node is idempotent; `tfe02` is provisioned fresh.

---

## Troubleshooting

**Precheck fails: "TFE image archive does not exist"**
- Transfer the TFE image archive to the TFE VM at the path set by `tfe_image_file` (default: `/tmp/terraform-for-z-2-0-5`).

**`setup.sh` lists empty configuration fields**
- Open [`setup.env`](setup.env), fill in every empty `""` value, and re-run `source setup.sh`.

**`.env` or `vars/secrets.yml` do not reflect your latest configuration changes**
- Re-run `source setup.sh` — both files are always fully regenerated on every run.

**`[5/5]` shows `MISSING` for one or more cert files**
- The variable is empty or points to a file that does not exist on the control machine.
- Set `TFE01_CERT`, `TFE01_KEY`, and/or `TFE01_BUNDLE` to valid absolute paths in the USER CONFIG block, then re-run `source setup.sh`.
- For `tfe02`, use `TFE02_CERT` / `TFE02_KEY` / `TFE02_BUNDLE`. The naming rule is: hostname uppercased with hyphens replaced by underscores, suffixed with `_CERT`, `_KEY`, or `_BUNDLE`.

**Deploy hangs at "Wait for TFE readiness"**
- This is expected — Vault HA lock acquisition on s390x takes 10–15 minutes on first boot.
- The playbook retries every 30 seconds for up to 30 minutes and prints progress each attempt.
- If it still fails: `podman logs terraform-enterprise-tfe` on VM1.

**Wrong image architecture error**
- Confirm the image file is the s390x build. The playbook expects `s390x/linux`.
- Check on the TFE VM: `podman image inspect <image> --format '{{.Architecture}}/{{.Os}}'`

**Admin user creation returns 401**
- The initial admin user already exists. Log in at `https://<VM1_ANSIBLE_HOST>/` with the credentials in `vars/secrets.yml`.

**HAProxy stats page**
- Accessible at `http://<VM1_ANSIBLE_HOST>:8404/stats` after a successful deployment.
