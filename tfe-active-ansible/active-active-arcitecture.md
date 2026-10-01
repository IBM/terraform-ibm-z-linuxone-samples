

Ideal Architecture for active-active mode tfe iinstallation....


                         ┌──────────────────────┐
                         │    Users / Clients   │
                         │                      │
                         │ Web / CLI / VCS /    │
                         │ CI-CD                │
                         └──────────┬───────────┘
                                    │
                                    │ HTTPS :443
                                    ▼
                         ┌──────────────────────┐
                         │       HAProxy        │
                         │                      │
                         │  Load Balancer       │
                         │  Health Checks       │
                         │  Failover            │
                         │                      │
                         │  tfe.company.com(VM1)│
                         └──────────┬───────────┘
                                    │
                         ┌──────────┴──────────┐
                         │                     │
                         ▼                     ▼
              ┌──────────────────┐   ┌──────────────────┐
              │   TFE Instance 1 │   │   TFE Instance 2 │
              │                  │   │                  │
              │   ACTIVE         │◄─►│   ACTIVE         │
              │                  │   │                  │
              │ RHEL / s390x     │   │ RHEL / s390x     │
              │ Podman           │   │ Podman           │
              │ TFE :8443        │   │ TFE :8443        │
              └────────┬─────────┘   └────────┬─────────┘
                       │                      │
                       │                      │
                       └──────────┬───────────┘
                                  │
                                  │ Shared Services
                                  ▼
                  ┌─────────────────────────────────┐
                  │       External Services VM      │
                  │            RHEL / x86_64        │
                  │                                 │
                  │              Podman             │
                  │                                 │
                  │   ┌────────────┐                │
                  │   │ PostgreSQL │ :5432          │
                  │   └────────────┘                │
                  │                                 │
                  │   ┌────────────┐                │
                  │   │   Redis    │ :6379          │
                  │   └────────────┘                │
                  │                                 │
                  │   ┌────────────┐                │
                  │   │   MinIO    │ :9000/9001     │
                  │   └────────────┘                │
                  │                                 │
                  └─────────────────────────────────┘


==============Execution Flow====================

                        Client
                        │
                        ▼
                        HAProxy
                        │
                        ├──────────────► TFE-01 ──────┐
                        │                             │
                        └──────────────► TFE-02 ──────┤
                                                      │
                                                      ▼
                                                External Services
                                                ├── PostgreSQL
                                                ├── Redis
                                                └── MinIO



Current Architecture for active-active mode tfe iinstallation....


                    ┌─────────────────────────┐
                    │     Users / Clients      │
                    │                         │
                    │  • Web Browser           │
                    │  • Terraform CLI         │
                    │  • VCS / GitHub          │
                    │  • CI/CD                 │
                    └────────────┬────────────┘
                                 │
                                 │ HTTPS :443
                                 ▼
┌──────────────────────────────────────────────────────────────┐
│                         VM1                                  │
│                    RHEL / s390x                              │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐  │
│  │                       HAProxy                          │  │
│  │                                                        │  │
│  │  • Load Balancer                                       │  │
│  │  • Health Check                                        │  │
│  │  • Single Entry Point                                  │  │
│  │  • Backend: TFE                                        │  │
│  └───────────────────────┬────────────────────────────────┘  │
│                          │                                   │
│                          │ HTTPS :8443                       │
│                          ▼                                   │
│  ┌────────────────────────────────────────────────────────┐  │
│  │                    TFE Instance 1                      │  │
│  │                                                        │  │
│  │  Terraform Enterprise                                 │  │
│  │  • Podman                                              │  │
│  │  • s390x                                               │  │
│  │  • ACTIVE                                               │  │
│  │  • HTTPS :8443                                         │  │
│  └────────────────────────┬───────────────────────────────┘  │
│                           │                                  │
└───────────────────────────┼──────────────────────────────────┘
                            │
                            │ External Services
                            │
                            ▼
┌──────────────────────────────────────────────────────────────┐
│                         VM2                                  │
│                    RHEL / x86_64                             │
│                                                              │
│                       Podman Containers                      │
│                                                              │
│  ┌──────────────────┐    ┌──────────────────┐                │
│  │    PostgreSQL    │    │      Redis       │                │
│  │                  │    │                  │                │
│  │    :5432         │    │      :6379       │                │
│  │                  │    │                  │                │
│  │  TFE Database    │    │ Cache / Sessions │                │
│  └──────────────────┘    └──────────────────┘                │
│                                                              │
│                    ┌──────────────────┐                      │
│                    │      MinIO       │                      │
│                    │                  │                      │
│                    │   :9000 / :9001  │                      │
│                    │                  │                      │
│                    │ S3 Object Store  │                      │
│                    │ State / Artifacts│                      │
│                    └──────────────────┘                      │
│                                                              │
└──────────────────────────────────────────────────────────────┘



==============Current Execution Flow====================


                    User
                    │
                    │ HTTPS :443
                    ▼
                    HAProxy
                    │
                    │ HTTPS :8443
                    ▼
                    TFE1
                    │
                    ├──────────► PostgreSQL :5432
                    │
                    ├──────────► Redis :6379
                    │
                    └──────────► MinIO :9000