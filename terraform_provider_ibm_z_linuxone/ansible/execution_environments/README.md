# Ansible Execution Environment for z/OS Core with Terraform

This document explains how to build, tag, and push a custom Ansible Execution Environment container image designed for managing z/OS Core infrastructure with Terraform integration.

## Table of Contents
- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Command Breakdown](#command-breakdown)
- [Step-by-Step Instructions](#step-by-step-instructions)

## Overview

The following workflow creates a specialized container image containing:
- Ansible with z/OS Core collection
- Terraform and related tools
- All necessary dependencies

The image is built locally and then published to Quay.io for use in automation controllers like AAP or AWX.

For more information on how to build Execuation Environment, please see https://docs.ansible.com/ansible/latest/getting_started_ee/index.html

## Prerequisites

Before running these commands, ensure you have:

1. **Software Installed**:
   - `ansible-builder` (from `ansible` package)
   - `podman` (or `docker` if preferred)
   - `git` (if cloning from source)

2. **Configuration**:
   - Valid `execution-environment.yml` file
   - Properly configured container runtime

3. **Quay.io Access**:
   - Account on [quay.io](https://quay.io)
   - Repository creation permissions
   - API token (if using automated login)

## Command Breakdown

### 1. Build the Execution Environment

```bash
ansible-builder build -v3 --container-runtime podman -t zoscore-terraform
```

| Parameter | Description |
|-----------|-------------|
| `build` | Builds the execution environment |
| `-v3` | Verbose output (level 3) |
| `--container-runtime podman` | Specifies Podman as container runtime |
| `-t zoscore-terraform` | Tags the resulting image |

### 2. Authenticate with Quay.io

```bash
podman login quay.io
```

Prompts for:
- Quay.io username
- Password (or API token)

### 3. Tag the Local Image

```bash
podman tag localhost/zoscore-terraform:latest quay.io/your-id/ansiblezos-terraform:latest
```

Replace placeholders:
- `your-id`: Your Quay.io username or organization
- `ansiblezos-terraform`: Desired repository name

### 4. Push to Quay.io

```bash
podman push quay.io/your-id/ansiblezos-terraform:latest
```

Uploads the image to your Quay.io repository.

## Step-by-Step Instructions

### 1. Build the Image

```bash
ansible-builder build -v3 --container-runtime podman -t zoscore-terraform
```

**Expected Output**:
```
Building Ansible Builder Container...
Step 1/12 : FROM quay.io/ansible/ansible-runner:latest
...
Successfully built abc123456789
Successfully tagged zoscore-terraform:latest
```

### 2. Log in to Container Registry

```bash
podman login quay.io
```

**Example Session**:
```
Username: your_quay_username
Password: 
Login Succeeded!
```

### 3. Tag the Image

```bash
podman tag localhost/zoscore-terraform:latest quay.io/your-team/ansiblezos-terraform:latest
```

**Note**: You can use semantic versioning instead of `latest`.

### 4. Push the Image

```bash
podman push quay.io/your-team/ansiblezos-terraform:latest
```

**Expected Output**:
```
Getting image source signatures
Copying blob sha256:abc123...
...
Storing signatures
```