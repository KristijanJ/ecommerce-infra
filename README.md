# ecommerce-infra

Docker Compose infrastructure for the ecommerce shop. It runs outside the Kubernetes cluster.

- PostgreSQL and Redis run the same way in every environment: Docker Compose locally (`local/`) and on a separate VM in Proxmox (`proxmox/`).
- LGTM observability (`grafana/otel-lgtm`) is local only. The Proxmox k3s cluster runs a different stack, deployed with Helm and ArgoCD from the gitops repo (see [Observability by environment](#observability-by-environment)).

Part of a multi-repo project:

| Repo                                                                         | Purpose                                                             |
| ---------------------------------------------------------------------------- | ------------------------------------------------------------------- |
| [ecommerce-infra](https://github.com/KristijanJ/ecommerce-infra)             | This repo. Docker Compose for PostgreSQL and Redis, plus local LGTM |
| [ecommerce-shop-gitops](https://github.com/KristijanJ/ecommerce-shop-gitops) | Kubernetes manifests, ArgoCD, platform tooling                      |
| [ecommerce-shop-be](https://github.com/KristijanJ/ecommerce-shop-be)         | Express.js REST API                                                 |
| [ecommerce-shop-fe](https://github.com/KristijanJ/ecommerce-shop-fe)         | Next.js frontend                                                    |

---

## Why Docker, not Kubernetes?

Stateful services (databases, caches) are intentionally kept out of Kubernetes, both locally and in production.

In production on AWS, PostgreSQL runs on RDS and Redis runs on ElastiCache. Both are managed services outside the EKS cluster. Running them in Docker locally mirrors that separation. If they were in the KinD cluster, the local setup would diverge from production and need StatefulSets, PersistentVolumes, and backup strategies that AWS manages for you.

| Service    | Local          | AWS (prod)  |
| ---------- | -------------- | ----------- |
| PostgreSQL | Docker Compose | RDS         |
| Redis      | Docker Compose | ElastiCache |

Swapping from local to AWS means changing a connection string. Nothing in the application code or k8s manifests changes.

---

## Services

### Stateful services (all environments)

#### PostgreSQL

- Image: `postgres:18.1`
- Port: `5432`
- Default credentials: `postgres / postgres`
- Database: `ecommerce`
- Data persisted to a named Docker volume (`postgres_data`)
- Health check: `pg_isready`

#### Redis

- Image: `redis:7.4`
- Port: `6379`
- No auth (local only)
- Data persisted to a named Docker volume (`redis_data`)
- Health check: `redis-cli ping`

### Observability by environment

| Environment            | Stack                                                             | Where it's defined                              |
| ---------------------- | ----------------------------------------------------------------- | ----------------------------------------------- |
| Local (Docker Compose) | LGTM: Grafana, Loki, Tempo, Prometheus, Pyroscope, OTel Collector | `local/docker-compose.yml` (this repo)          |
| Proxmox k3s            | PLG: kube-prometheus-stack (Prometheus + Grafana), Loki, Promtail | Helm charts via ArgoCD, `ecommerce-shop-gitops` |

The two stacks are not equivalent. The local stack adds Tempo (traces), Pyroscope (profiles) and an OTLP endpoint, which the homelab stack lacks. Both have logs and metrics, collected differently: apps push OTLP locally, and Promtail scrapes pod logs on k3s. Something visible in local Grafana may not exist on the cluster, and the reverse.

### LGTM (local only)

All-in-one observability backend for local development, based on [`grafana/otel-lgtm`](https://github.com/grafana/docker-otel-lgtm). The Proxmox setup doesn't include it. `proxmox/docker-compose.yml` runs only PostgreSQL and Redis.

- Image: `grafana/otel-lgtm:0.34.0`
- Ports:

| Host   | Container | What                            |
| ------ | --------- | ------------------------------- |
| `3300` | `3000`    | Grafana UI (`admin` / `admin`)  |
| `3200` | `3200`    | Tempo                           |
| `4040` | `4040`    | Pyroscope                       |
| `4317` | `4317`    | OTLP gRPC (send telemetry here) |
| `4318` | `4318`    | OTLP HTTP (send telemetry here) |
| `9090` | `9090`    | Prometheus                      |

- Grafana is published on host port `3300` instead of the default `3000` to avoid clashing with other local tools
- Data persisted to named Docker volumes, one per component, so a single store can be reset on its own: `lgtm_grafana`, `lgtm_prometheus`, `lgtm_loki`, `lgtm_tempo`, `lgtm_pyroscope`
- Runs with `init: true` (the image supervises several processes in one container)
- Optional settings such as `OTEL_COLLECTOR_DEBUG_EXPORTER` go in `local/.env`, which `make start-local` creates

---

## Quick start

```bash
make start-local    # start PostgreSQL, Redis and LGTM (local only) in the background
```

`make start-local` creates `local/.env` from `local/.env.example` if it doesn't exist yet. `.env` is gitignored, so edit it freely. Put new variables and their defaults in `.env.example`.

```bash
make check-requirements    # verify Docker is installed and running
```

To stop:

```bash
docker compose -f local/docker-compose.yml down
```

To wipe data volumes (Postgres, Redis and all LGTM data):

```bash
docker compose -f local/docker-compose.yml down -v
```

To reset a single LGTM store, stop the stack and remove just that volume, e.g. `docker volume rm local_lgtm_loki` (volumes are prefixed with the Compose project name, `local`).

---

## Connecting

PostgreSQL and Redis are exposed on `localhost` and on `host.docker.internal` (reachable from inside the KinD cluster):

| Service    | localhost        | From KinD cluster           |
| ---------- | ---------------- | --------------------------- |
| PostgreSQL | `localhost:5432` | `host.docker.internal:5432` |
| Redis      | `localhost:6379` | `host.docker.internal:6379` |

The backend connects to PostgreSQL and the frontend connects to Redis using the `host.docker.internal` hostname, which is set via environment variables managed by [Vault + ESO](https://github.com/KristijanJ/ecommerce-shop-gitops).

The local LGTM stack is also exposed:

| Service      | localhost        | From KinD cluster           |
| ------------ | ---------------- | --------------------------- |
| OTLP gRPC    | `localhost:4317` | `host.docker.internal:4317` |
| OTLP HTTP    | `localhost:4318` | `host.docker.internal:4318` |
| Grafana (UI) | `localhost:3300` | (browser only)              |

On the Proxmox cluster, Grafana comes from kube-prometheus-stack instead (`make grafana-ui` in the gitops repo).
