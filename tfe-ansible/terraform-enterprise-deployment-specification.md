# Terraform Enterprise Deployment Specification

## 1. Purpose

This specification provides a high-level map of the different ways Terraform Enterprise (TFE) can be deployed and operated.

The key distinction is:

- **Deployment runtime** — how/where the TFE container/application runs.
- **Operational mode** — how TFE's persistent application data and supporting services are handled.

---

# 2. High-Level Architecture

```text
                         TERRAFORM ENTERPRISE
                                  |
                    +-------------+-------------+
                    |                           |
             DEPLOYMENT RUNTIME            OPERATIONAL MODE
             "HOW TFE RUNS"               "HOW DATA IS STORED"
                    |                           |
        +-----------+-----------+        +------+-------+
        |           |           |        |      |       |
      Docker    Kubernetes    Podman    disk  external active-active
        |           |           |        |      |       |
        |           |           |        |      |       |
        +-----------+-----------+        +------+-------+
                    |
              Other runtimes
                    |
              +-----+------+
              |            |
           OpenShift     Nomad
```

The important mental model is:

> Docker, Podman, Kubernetes, OpenShift, and Nomad describe the deployment/runtime platform.

> `disk`, `external`, and `active-active` describe the TFE operational/data architecture.

---

# 3. Deployment Runtime Options

## 3.1 Docker

Typical architecture:

```text
                    Linux VM
                       |
                 Docker Engine
                       |
                 Docker Compose
                       |
              +------------------+
              | TFE Container    |
              |                  |
              | Terraform        |
              | Nginx            |
              | TFE services     |
              +--------+---------+
                       |
                Persistent storage
```

Typical deployment mechanism:

```bash
docker compose up -d
```

Docker is useful for:

- Development
- Lab environments
- Single-VM deployments
- Production deployments where Docker is the organization's standard

---

# 3.2 Podman

Typical architecture:

```text
                    RHEL VM
                       |
                     Podman
                       |
                podman kube play
                       |
                +--------------+
                | TFE Pod      |
                |              |
                | TFE Container|
                +------+-------+
                       |
                Persistent storage
```

# . MY Current TFE Architecture

My current environment:

```text
RHEL 9.8(VM)
    |
    +-- Podman 5.8.2
          |
          +-- podman kube play
                |
                +-- terraform-enterprise Pod
                      |
                      +-- TFE Container
                            |
                            +-- Port 80
                            +-- Port 443
                            +-- Port 9090
                            |
                            +-- /opt/tfe/data
                            +-- /opt/tfe/certs
```

Conceptually:

```text
                 MY CURRENT SETUP
                        |
             +----------+----------+
             |                     |
          Runtime              Storage
             |                     |
          Podman                  disk
             |                     |
      podman kube play       /opt/tfe/data
             |
        TFE Container
```

---

# 3.3 Kubernetes

Typical architecture:

```text
                 Kubernetes Cluster
                        |
                    Namespace
                        |
                    Helm Chart
                        |
              +---------+---------+
              |                   |
           TFE Pod             Services
              |                   |
        TFE Container         LoadBalancer
```

Typical deployment mechanism:

```text
Helm
  |
  +-- TFE deployment
  +-- Services
  +-- Secrets
  +-- Persistent resources
```

Kubernetes is generally the preferred direction when:

- TFE needs to run in a container orchestration platform
- High availability/scaling is required
- The organization already operates Kubernetes
- Infrastructure is managed through Helm/Kubernetes tooling

---

# 3.4 OpenShift

OpenShift is Kubernetes-based and adds Red Hat-specific security and platform capabilities.

```text
                 OpenShift Cluster
                        |
                   Project/Namespace
                        |
                     TFE Pods
                        |
                +-------+-------+
                |               |
             TFE Pod         Services/Route
                |
          TFE Container
```

Useful when the organization already has an OpenShift platform.

---

# 3.5 Nomad

Typical architecture:

```text
                 Nomad Cluster
                      |
                  Nomad Job
                      |
               +--------------+
               | TFE          |
               | Allocation   |
               |              |
               | Container    |
               +--------------+
```

Nomad is relevant when HashiCorp Nomad is already the organization's container/workload orchestrator.

---

# 4. Operational Modes

The runtime and operational mode are separate concepts.

The main operational modes to understand are:

```text
                       TFE
                        |
             +----------+----------+
             |          |          |
            disk      external  active-active
             |          |          |
          Local       External   External
          storage     services   services
```

---

# 5. Disk Mode

Disk mode is the good architecture for a small environment.

```text
                    RHEL VM
                       |
                     Podman
                       |
                +--------------+
                | TFE          |
                | Container    |
                +------+-------+
                       |
                 Persistent disk
                       |
                 /opt/tfe/data
```

Conceptually:

```text
TFE
 |
 +-- Application
 |
 +-- PostgreSQL data
 |
 +-- Object/application data
 |
 +-- Persistent local storage
```

### Advantages

- Simple
- Easy to understand
- Good for development/POC
- Minimal external dependencies

### Disadvantages

- Tied to local persistent storage
- Not ideal for horizontal scaling
- Disaster recovery is more dependent on the VM/storage
- Less suitable for highly available production architectures

---

# 6. External Mode

External mode moves important supporting services outside the TFE container/VM.

```text
                 +----------------+
                 | TFE VM         |
                 |                |
                 | TFE Container  |
                 +-------+--------+
                         |
              +----------+----------+
              |                     |
              v                     v
        PostgreSQL              S3/Object
        External               Storage
```

Conceptually:

```text
TFE
 |
 +-- External PostgreSQL
 |
 +-- External object storage
 |
 +-- Other required external services
```

Examples of external infrastructure could include:

- PostgreSQL service
- S3-compatible object storage
- Cloud-managed database/storage services

### Advantages

- Better separation of application and data
- Easier database backup/management
- Better durability
- Better suited to production environments

### Disadvantages

- More infrastructure
- More configuration
- More credentials/secrets
- More operational dependencies

---

# 7. Active-Active Mode

Active-active is designed for multiple TFE instances.

```text
                       Load Balancer
                            |
                +-----------+-----------+
                |           |           |
                v           v           v
              TFE-1       TFE-2       TFE-3
                |           |           |
                +-----------+-----------+
                            |
             +--------------+--------------+
             |              |              |
             v              v              v
        PostgreSQL        S3/Object       Redis
         External         Storage        External
```

This architecture provides:

- Multiple TFE instances
- Horizontal scalability
- Higher availability
- Load balancing
- External shared services

A simplified view:

```text
                    Load Balancer
                         |
            +------------+------------+
            |            |            |
           TFE          TFE          TFE
            |            |            |
            +------------+------------+
                         |
              Shared external services
                         |
             +-----------+-----------+
             |           |           |
            PG          S3         Redis
```

---

# 8. Runtime vs Operational Mode Matrix

| Runtime | Typical deployment | Disk | External | Active-Active |
|---|---|---:|---:|---:|
| Docker | Docker Compose | Yes | Yes | Yes |
| Podman | Podman / Kubernetes YAML | Yes | Yes | Yes |
| Kubernetes | Helm | Not typically selected directly | Yes | Yes |
| OpenShift | Kubernetes/OpenShift tooling | Not typically selected directly | Yes | Yes |
| Nomad | Nomad job | Yes | Yes | Yes |

The exact supported combinations should always be checked against the TFE version being deployed.

---

---

# 10. Which Architecture Should You Use?

## Learning / Lab / POC

Recommended:

```text
RHEL
 |
 +-- Podman
      |
      +-- TFE
           |
           +-- Disk storage
```

This is close to what you are currently building with Ansible.

---

## Production - Single TFE Instance

A common architecture to consider:

```text
                 Load Balancer / Reverse Proxy
                           |
                          TFE
                           |
                 +---------+---------+
                 |                   |
          PostgreSQL             S3/Object
           External               Storage
```

This separates the TFE application from important persistent services.

---

## Production - High Availability

Consider:

```text
                     Load Balancer
                          |
             +------------+------------+
             |            |            |
            TFE          TFE          TFE
             |            |            |
             +------------+------------+
                          |
             +------------+-------------+
             |            |             |
            PG           S3           Redis
         External      External       External
```

This is the architecture to think about when availability and scaling are important.

---

# 11. Decision Tree

```text
                         Need TFE?
                            |
                            v
                 What platform do you have?
                            |
          +---------+-------+--------+---------+
          |         |                |         |
        RHEL      Docker        Kubernetes  OpenShift
          |                         |
        Podman                    Helm
          |                         |
          +------------+------------+
                       |
                       v
                How much scale?
                       |
              +--------+--------+
              |                 |
             Lab            Production
              |                 |
              v                 v
            disk          external services
                                |
                                v
                         Need HA / scale?
                           /          \
                         No            Yes
                         |              |
                     external     active-active
```

---

# 12. Key Concepts to Remember

### Deployment Runtime

Answers:

> "How is TFE running?"

Examples:

```text
Docker
Podman
Kubernetes
OpenShift
Nomad
```

### Operational Mode

Answers:

> "Where does TFE keep/manage its persistent data and supporting services?"

Examples:

```text
disk
external
active-active
```

### Your Current Setup

```text
Runtime:
    Podman

Orchestration:
    podman kube play

Operational architecture:
    disk

Host:
    RHEL 9.8

TFE:
    2.0.5

Architecture:
    x86_64
```

---

# 13. Practical Progression for Your Ansible Project

Given that you are learning TFE deployment and automating it with Ansible, a useful progression would be:

```text
Step 1
Podman + disk
    |
    |  <-- You are here
    v
Step 2
Podman + external PostgreSQL/S3
    |
    v
Step 3
Automate configuration/secrets
    |
    v
Step 4
Automate health/readiness
    |
    v
Step 5
Automate initial admin bootstrap
    |
    v
Step 6
Kubernetes + Helm
    |
    v
Step 7
Kubernetes + active-active
```

This progression lets you understand the architecture before introducing Kubernetes and high availability.

---

# 14. Useful Terminology

| Term | Meaning |
|---|---|
| TFE | Terraform Enterprise |
| Podman | Container runtime |
| Docker | Container runtime |
| Kubernetes | Container orchestration platform |
| OpenShift | Red Hat Kubernetes platform |
| Nomad | Workload/container orchestrator |
| Pod | Group of containers managed together |
| Container | TFE application runtime |
| Helm | Kubernetes package/deployment manager |
| Disk mode | Persistent storage managed through disk/local storage |
| External mode | Persistent supporting services managed externally |
| Active-active | Multiple TFE instances operating together |
| PostgreSQL | TFE database |
| S3/object storage | TFE object/blob storage |
| Redis | Shared service used in applicable architectures |
| Load balancer | Distributes requests among TFE instances |

---

# 15. Final Mental Model

The easiest way to remember the whole TFE deployment landscape is:

```text
                         TFE
                          |
              +-----------+-----------+
              |                       |
          WHERE/HOW?              HOW DATA?
              |                       |
              v                       v
        Deployment Runtime      Operational Mode
              |                       |
      +-------+-------+         +-----+-----+
      |       |       |         |     |     |
    Docker  Podman  K8s       disk external A-A
              |       |
           OpenShift  |
              |      Helm
             Nomad
```

My your current project:

```text
                TFE 2.0.5
                    |
                  RHEL 9.8
                    |
                  Podman
                    |
             podman kube play
                    |
             TFE Kubernetes YAML
                    |
              TFE Container
                    |
              Persistent Disk
                    |
               /opt/tfe/data
```

This is the baseline architecture from which you can move toward external services and eventually active-active deployments.


Current Install Approach
<==============================>

Install Podman
      ↓
Create TFE directories
      ↓
Configure certificates
      ↓
Pull TFE image
      ↓
Start TFE Podman pod
      ↓
Check container is running
      ↓
Check TFE logs
      ↓
Wait for HTTPS :443
      ↓
tfectl app health readiness
      ↓
      ├── NOT READY → retry
      │
      └── READY
            ↓
    Check admin marker
            ↓
       ┌────┴────┐
       │         │
     Exists    Doesn't exist
       │         │
      Skip     Get IACT
                 ↓
          Create admin
                 ↓
          Create marker
                 ↓
          Installation done





Current Delete Steps...
<==============================>


            TFE_DELETE_DATA
                │
        ┌─────────┴─────────┐
        │                   │
    false                true
        │                   │
Keep /data           Delete /data
        │                   │
Keep marker           Delete marker
        │                   │
Skip admin            Create admin
bootstrap             bootstrap