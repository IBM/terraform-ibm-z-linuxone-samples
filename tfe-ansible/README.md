# Terraform Enterprise — Ansible Playbook

Ansible playbook to install and configure [Terraform Enterprise (TFE)](https://developer.hashicorp.com/terraform/enterprise) on a Linux host using Podman.

---

## Prerequisites

- **Python 3** installed on your local machine — required to create the `.ansible-env` virtual environment (`python3 -m venv` bootstraps from the system Python; Ansible itself runs inside the venv)
- **OpenSSL** installed on your local machine — required to generate TLS certificates and the encryption password
- **Git** installed on your local machine — required to clone the repository
- SSH access to the target host
- A valid Terraform Enterprise license

---

## Project Structure

```
tfe-ansible/
├── files/
│   └── certs/               # TLS certificates (cert.pem, key.pem, bundle.pem)
├── host_vars/
│   └── <host-ip-address>.yml  # Host-specific Ansible connection variables
├── templates/
│   └── tfe-kube.yml.j2      # Podman Kubernetes manifest template
├── inventory.ini             # Ansible inventory
├── install-tfe.yml           # Main installation playbook
├── create-tfe-initial-admin.yml  # Initial admin creation playbook
├── uninstall-tfe.yml         # Uninstallation playbook
└── tfe-example.env           # Environment variable template
```

---

## Automated Setup

All setup steps can be performed in one go using `setup.sh`.

**1.** Clone the repository:

```bash
git clone https://github.com/IBM/terraform-ibm-z-linuxone-samples.git
```

**2.** Change into the `tfe-ansible` directory:

```bash
cd terraform-ibm-z-linuxone-samples/tfe-ansible
```

**3.** Open `setup.sh` and fill in the configuration block at the top of the file:

```bash
TFE_HOSTNAME=""            # domain name of the host, e.g. tfe.example.com  (used in tfe.env and TLS cert)
TFE_HOST_IP=""             # IP address of the host, e.g. 192.168.1.100     (used for SSH/inventory and TLS cert SAN)
TFE_LICENSE=""             # Terraform Enterprise license string
TFE_ENCRYPTION_PASSWORD=""

TFE_ADMIN_USERNAME=""      # e.g. admin
TFE_ADMIN_EMAIL=""         # e.g. admin@example.com
TFE_ADMIN_PASSWORD=""      # e.g. MySecurePassword123!

ANSIBLE_USER=""            # SSH username on the target host
ANSIBLE_PASSWORD=""        # SSH password for the above user
```

**4.** Source the script:

```bash
source setup.sh
```

> **Why `source` and not `bash`?**
> Running with `bash setup.sh` spawns a child process — the virtual environment gets activated inside that child, then disappears when the script exits.
> Running with `source setup.sh` (or `. setup.sh`) executes everything in your current shell, so the venv activation persists and `ansible` is available directly after the script completes.

The script will automatically:
- Validate that all required values are filled in
- Create and populate `tfe.env` from `tfe-example.env`
- Update `inventory.ini` with `TFE_HOST_IP`
- Rename `host_vars/<host-ip-address>.yml` to `host_vars/<TFE_HOST_IP>.yml`
- Generate a self-signed TLS certificate in `files/certs/` with `CN=TFE_HOSTNAME` and a SAN covering both the domain name and host IP
- Create the `.ansible-env` virtual environment and activate it in your shell

**5.** Once complete, your prompt will show `(.ansible-env)` and you can run the playbook directly:

```bash
source tfe.env && ansible-playbook -i inventory.ini install-tfe.yml
```

---

## Manual Setup Steps

### Step 1 — Clone the repository

```bash
git clone https://github.com/IBM/terraform-ibm-z-linuxone-samples.git
```

---

### Step 2 — Change into the `tfe-ansible` directory

```bash
cd terraform-ibm-z-linuxone-samples/tfe-ansible
```

---

### Step 3 — Create `tfe.env` from the example file

Copy the example environment file and use it as the basis for your configuration:

```bash
cp tfe-example.env tfe.env
```

> `tfe.env` is listed in `.gitignore` and will not be committed to source control.

---

### Step 4 — Set up the Python virtual environment and install Ansible

Create and activate a virtual environment, then install Ansible:

```bash
python3 -m venv .ansible-env
source .ansible-env/bin/activate
python -m pip install --upgrade pip
pip install ansible
```

To deactivate the virtual environment when finished:

```bash
deactivate
```

---

### Step 5 — Set `TFE_HOSTNAME` and `TFE_HOST_IP`

Open `tfe.env` and set both values:

```bash
# tfe.env
TFE_HOSTNAME=tfe.example.com   # domain name of the host
TFE_HOST_IP=192.168.1.100      # IP address of the host
```

`TFE_HOSTNAME` is used by TFE itself (HTTPS endpoint, TLS cert CN/SAN).
`TFE_HOST_IP` is used by Ansible to connect via SSH and is set in `inventory.ini`.

Update `inventory.ini` with the IP address:

```ini
[tfe]
192.168.1.100
```

---

### Step 6 — Rename the `host_vars` file

The file `host_vars/<host-ip-address>.yml` must be renamed to match `TFE_HOST_IP` so that Ansible can resolve the host variables correctly:

```bash
mv host_vars/<host-ip-address>.yml host_vars/192.168.1.100.yml
```

Replace `192.168.1.100` with the actual value you used for `TFE_HOST_IP`.

---

### Step 7 — Set the TFE license

Open `tfe.env` and replace the `<tfe-license>` placeholder with your Terraform Enterprise license string:

```bash
# tfe.env
TFE_LICENSE=<tfe-license>   # replace with your actual license
```

> The license is also used as the password to authenticate against the HashiCorp container registry (`images.releases.hashicorp.com`) to pull the TFE image.

---

### Step 8 — Set the encryption password

Replace the `<tfe-encryption-pass>` placeholder in `tfe.env` with a strong password. This value is used to encrypt sensitive data at rest inside TFE.

Generate a random password with:

```bash
openssl rand -base64 32
```

Copy the output and set it in `tfe.env`:

```bash
# tfe.env
TFE_ENCRYPTION_PASSWORD=<tfe-encryption-pass>   # paste the generated value here
```

> **Important:** Store this password securely. You will need it if you ever restore a TFE backup.

---

### Step 9 — Set the initial admin credentials and SSH connection details

Replace the remaining placeholders in `tfe.env` with the appropriate values:

| Variable | Placeholder | Description |
|----------|-------------|-------------|
| `TFE_ADMIM_USERNAME` | `<initial-admin>` | Username for the first TFE admin account |
| `TFE_ADMIM_EMAIL` | `<initial-email>` | Email address for the first TFE admin account |
| `TFE_ADMIM_PASSWORD` | `<initial-pass>` | Password for the first TFE admin account |
| `ANSIBLE_USER` | `<host-user-name>` | SSH username Ansible will use to connect to the host |
| `ANSIBLE_PASSWORD` | `<host-pass>` | SSH password for the above user |

```bash
# tfe.env — initial admin
TFE_ADMIM_USERNAME=admin
TFE_ADMIM_EMAIL=admin@example.com
TFE_ADMIM_PASSWORD=MySecurePassword123!

# tfe.env — SSH connection (exported so Ansible picks them up)
export ANSIBLE_USER=rhel-user
export ANSIBLE_PASSWORD=MySSHPassword
```

> **Tip:** Instead of storing SSH credentials in `tfe.env`, you can export them directly in your terminal session before running the playbook.

---

### Step 10 — Generate and place TLS certificates

Generate a self-signed certificate and private key for your TFE host. The certificate CN and DNS SAN use `TFE_HOSTNAME` (domain name); the IP SAN uses `TFE_HOST_IP`:

```bash
openssl req -x509 -newkey rsa:4096 -sha256 -days 365 -nodes \
  -keyout files/certs/tfe01/key.pem \
  -out    files/certs/tfe01/cert.pem \
  -subj   "/CN=tfe.example.com" \
  -addext "subjectAltName=DNS:tfe.example.com,IP:192.168.1.100"
```

Since this is a self-signed certificate, copy the certificate itself as the CA bundle:

```bash
cp files/certs/tfe01/cert.pem files/certs/tfe01/bundle.pem
```

The following files are now required by the playbook:

| File | Description |
|------|-------------|
| `files/certs/tfe01/cert.pem` | TFE server certificate |
| `files/certs/tfe01/key.pem` | TFE server private key |
| `files/certs/tfe01/bundle.pem` | CA certificate bundle (copy of cert.pem for self-signed) |

---

## Running the Playbook

Source the environment file to export all variables into your shell session, then run the playbook:

```bash
source tfe.env
ansible-playbook -i inventory.ini install-tfe.yml
```

The playbook will:
1. Install Podman on the target host
2. Pull the Terraform Enterprise container image from the HashiCorp registry
3. Deploy TFE using a Podman Kubernetes manifest
4. Wait for TFE to become ready
5. Create the initial administrator account

---

## Uninstalling TFE

To uninstall Terraform Enterprise from the target host:

```bash
source tfe.env
ansible-playbook -i inventory.ini uninstall-tfe.yml
```

> Set `TFE_DELETE_DATA=true` in `tfe.env` to also remove all TFE data directories during uninstall.

---

## Environment Variable Reference

| Variable | Default | Required | Description |
|----------|---------|----------|-------------|
| `TFE_VERSION` | `2.0.5` | Yes | TFE release version to deploy |
| `TFE_HOSTNAME` | — | Yes | Domain name of the target host (used in TFE config and TLS cert CN/SAN) |
| `TFE_HOST_IP` | — | Yes | IP address of the target host (used for SSH/inventory and TLS cert SAN) |
| `TFE_OPERATIONAL_MODE` | `disk` | Yes | TFE operational mode (`disk`, `active-active`, etc.) |
| `TFE_INSTALL_DIR` | `/opt/tfe` | Yes | Directory on the host where TFE files will be stored |
| `TFE_IMAGE` | `images.releases.hashicorp.com/hashicorp/terraform-enterprise` | Yes | Container image path |
| `TFE_HTTP_PORT` | `8080` | Yes | HTTP port |
| `TFE_HTTPS_PORT` | `8443` | Yes | HTTPS port |
| `TFE_ADMIN_HTTPS_PORT` | `8446` | Yes | Admin HTTPS port |
| `TFE_LICENSE` | — | Yes | TFE license string (also used as registry password) |
| `TFE_ENCRYPTION_PASSWORD` | — | Yes | Encryption password for TFE data at rest |
| `TFE_ADMIM_USERNAME` | — | Yes | Initial admin username |
| `TFE_ADMIM_EMAIL` | — | Yes | Initial admin email |
| `TFE_ADMIM_PASSWORD` | — | Yes | Initial admin password |
| `TFE_DELETE_DATA` | `true` | No | Whether to delete data on uninstall |
| `ANSIBLE_USER` | — | Yes | SSH username for the target host |
| `ANSIBLE_PASSWORD` | — | Yes | SSH password for the target host |
