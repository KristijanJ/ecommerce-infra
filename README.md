# ecommerce-infra

Infrastructure for the ecommerce shop that lives outside the Kubernetes manifests:

- `aws/` is the Terraform for the EKS cluster, VPC, RDS and the secrets in AWS Secrets Manager.
- `proxmox/` is the Docker Compose file and Ansible playbook for the services VM that runs PostgreSQL and Redis for the homelab cluster.
- `local/` is Docker Compose for local development: PostgreSQL, Redis and an all-in-one Grafana LGTM stack.

Part of a multi-repo project:

| Repo                                                                         | Purpose                                                  |
| ---------------------------------------------------------------------------- | -------------------------------------------------------- |
| [ecommerce-infra](https://github.com/KristijanJ/ecommerce-infra)             | This repo. Terraform for AWS, Docker Compose and Ansible |
| [ecommerce-shop-gitops](https://github.com/KristijanJ/ecommerce-shop-gitops) | Kubernetes manifests, ArgoCD, platform tooling           |
| [ecommerce-shop-be](https://github.com/KristijanJ/ecommerce-shop-be)         | NestJS REST API                                          |
| [ecommerce-shop-fe](https://github.com/KristijanJ/ecommerce-shop-fe)         | Next.js frontend                                         |

---

## Where the stateful services run

| Service    | Local          | Homelab (Proxmox)                 | AWS (aws-prod)                                   |
| ---------- | -------------- | --------------------------------- | ------------------------------------------------ |
| PostgreSQL | Docker Compose | Docker Compose on the services VM | RDS, created by Terraform                        |
| Redis      | Docker Compose | Docker Compose on the services VM | A Deployment in the cluster, without persistence |

PostgreSQL stays outside Kubernetes in every environment. On AWS the frontend's Redis runs in the cluster, because it only holds shopping carts and losing them on a restart is acceptable. That manifest is in the gitops repo (`apps/frontend/envs/aws-prod/redis.yaml`).

---

## Repository layout

```text
aws/
├── README.md                     how to run the Terraform
└── terraform/
    ├── environments/prod/        root module, backend, providers, variables
    └── modules/
        ├── networking/           VPC with public, private and database subnets
        ├── eks/                  EKS cluster, node group, add-ons, IAM roles, Load Balancer Controller
        └── rds/                  RDS PostgreSQL, security group, connection secret
local/                            Docker Compose: PostgreSQL, Redis, LGTM
proxmox/
├── docker-compose.yml            PostgreSQL and Redis for the services VM
└── ansible/                      installs Docker on the VM and starts the compose file
scripts/check-local-requirements.sh
Makefile
```

---

## Local development

```bash
make check-requirements   # check that Docker is installed and running
make start-local          # start PostgreSQL, Redis and LGTM in the background
```

`make start-local` creates `local/.env` from `local/.env.example` if it does not exist. `.env` is gitignored. Add new variables and their defaults to `.env.example`.

Stop the stack:

```bash
docker compose -f local/docker-compose.yml down
```

Remove the data volumes too (PostgreSQL, Redis and all LGTM data):

```bash
docker compose -f local/docker-compose.yml down -v
```

To reset one LGTM store, stop the stack and remove that volume. Volumes carry the Compose project name `local` as a prefix, for example `docker volume rm local_lgtm_loki`.

### PostgreSQL

- Image `postgres:18.1`, port `5432`
- User and password `postgres` / `postgres`, database `ecommerce`
- Data in the named volume `postgres_data`
- Health check with `pg_isready`

### Redis

- Image `redis:7.4`, port `6379`, no authentication
- Data in the named volume `redis_data`
- Health check with `redis-cli ping`

### LGTM

`grafana/otel-lgtm:0.34.0` bundles Grafana, Loki, Tempo, Prometheus, Pyroscope and an OpenTelemetry Collector in one container. It is only part of the local stack. The Proxmox compose file runs just PostgreSQL and Redis.

| Host port | Container port | What                           |
| --------- | -------------- | ------------------------------ |
| `3300`    | `3000`         | Grafana UI (`admin` / `admin`) |
| `3200`    | `3200`         | Tempo                          |
| `4040`    | `4040`         | Pyroscope                      |
| `4317`    | `4317`         | OTLP gRPC, send telemetry here |
| `4318`    | `4318`         | OTLP HTTP, send telemetry here |
| `9090`    | `9090`         | Prometheus                     |

Grafana is published on `3300` so it does not clash with other tools on `3000`. Each component has its own volume (`lgtm_grafana`, `lgtm_prometheus`, `lgtm_loki`, `lgtm_tempo`, `lgtm_pyroscope`). The container runs with `init: true` because the image starts several processes.

### Connecting

The databases and the OTLP endpoints listen on `localhost`. A kind cluster reaches them through `host.docker.internal`:

| Service    | From the host    | From a kind cluster         |
| ---------- | ---------------- | --------------------------- |
| PostgreSQL | `localhost:5432` | `host.docker.internal:5432` |
| Redis      | `localhost:6379` | `host.docker.internal:6379` |
| OTLP gRPC  | `localhost:4317` | `host.docker.internal:4317` |
| OTLP HTTP  | `localhost:4318` | `host.docker.internal:4318` |
| Grafana    | `localhost:3300` | browser only                |

In the clusters the apps read these settings from Kubernetes Secrets, which External Secrets fills from Vault or Secrets Manager (see the [gitops repo](https://github.com/KristijanJ/ecommerce-shop-gitops)).

---

## Proxmox services VM

The homelab cluster uses a separate VM (`192.168.0.30`) for PostgreSQL and Redis. `proxmox/docker-compose.yml` defines the same two services as the local file, without LGTM.

The Ansible playbook `proxmox/ansible/setup_playbook.yml` installs Docker on the VM, adds the `ubuntu` user to the `docker` group, copies the compose file to `/opt/ecommerce-infra` and starts it. The inventory is `proxmox/ansible/inventory.yaml`.

```bash
cd proxmox/ansible
ansible-playbook -i inventory.yaml setup_playbook.yml
```

---

## AWS

`aws/terraform/environments/prod` creates the aws-prod environment. The cluster is destroyed after each working session to save money, so apply and destroy are part of the normal routine. See [aws/README.md](aws/README.md) for the full steps.

```bash
make aws-tf-init        # once per checkout
make aws-tf-plan
make aws-tf-apply
# then in the gitops repo: make start-aws-prod
```

To tear it down, run `make teardown-aws-prod` in the gitops repo first, then `make aws-tf-destroy` here.

---

## Makefile reference

`make help` prints the full list.

| Target               | What it does                                            |
| -------------------- | ------------------------------------------------------- |
| `check-requirements` | Checks the local tools                                  |
| `start-local`        | Starts the local Docker Compose stack                   |
| `aws-tf-init`        | Initializes Terraform for an environment                |
| `aws-tf-plan`        | Runs `terraform plan`                                   |
| `aws-tf-apply`       | Runs `terraform apply`                                  |
| `aws-tf-destroy`     | Runs `terraform destroy`. Run the gitops teardown first |
| `aws-tf-fmt`         | Runs `terraform fmt -recursive` on `aws/terraform`      |
| `aws-tf-validate`    | Runs `terraform validate` for an environment            |

The `aws-tf-*` targets ask for the environment name and, for `init`, the SSO profile.
