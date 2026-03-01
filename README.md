# ecommerce-infra

Local infrastructure for the ecommerce shop. Runs PostgreSQL and Redis via Docker Compose for local development alongside the Kubernetes cluster.

Part of a multi-repo project:

| Repo                                                                         | Purpose                                                       |
| ---------------------------------------------------------------------------- | ------------------------------------------------------------- |
| [ecommerce-infra](https://github.com/KristijanJ/ecommerce-infra)             | **This repo** - Local Docker Compose for PostgreSQL and Redis |
| [ecommerce-shop-gitops](https://github.com/KristijanJ/ecommerce-shop-gitops) | Kubernetes manifests, ArgoCD, platform tooling                |
| [ecommerce-shop-be](https://github.com/KristijanJ/ecommerce-shop-be)         | Express.js REST API                                           |
| [ecommerce-shop-fe](https://github.com/KristijanJ/ecommerce-shop-fe)         | Next.js frontend                                              |

---

## Why Docker, not Kubernetes?

Stateful services (databases, caches) are intentionally kept out of Kubernetes — both locally and in production.

In production on AWS, PostgreSQL runs on **RDS** and Redis runs on **ElastiCache**: managed services outside the EKS cluster. Running them in Docker locally mirrors this separation exactly. If they were in the KinD cluster instead, the local setup would diverge from production and require StatefulSets, PersistentVolumes, and backup strategies that AWS manages for you.

| Service    | Local          | AWS (prod)  |
| ---------- | -------------- | ----------- |
| PostgreSQL | Docker Compose | RDS         |
| Redis      | Docker Compose | ElastiCache |

Swapping from local to AWS means changing a connection string — nothing in the application code or k8s manifests changes.

---

## Services

### PostgreSQL

- Image: `postgres:18.1`
- Port: `5432`
- Default credentials: `postgres / postgres`
- Database: `ecommerce`
- Data persisted to a named Docker volume (`postgres_data`)
- Health check: `pg_isready`

### Redis

- Image: `redis:7.4`
- Port: `6379`
- No auth (local only)
- Data persisted to a named Docker volume (`redis_data`)
- Health check: `redis-cli ping`

---

## Quick Start

```bash
make start-local    # start PostgreSQL and Redis in the background
```

```bash
make check-requirements    # verify Docker is installed and running
```

To stop:

```bash
docker compose -f local/docker-compose.yml down
```

To wipe data volumes:

```bash
docker compose -f local/docker-compose.yml down -v
```

---

## Connecting

Both services are exposed on `localhost` and on `host.docker.internal` (reachable from inside the KinD cluster):

| Service    | localhost        | From KinD cluster           |
| ---------- | ---------------- | --------------------------- |
| PostgreSQL | `localhost:5432` | `host.docker.internal:5432` |
| Redis      | `localhost:6379` | `host.docker.internal:6379` |

The backend connects to PostgreSQL and the frontend connects to Redis using the `host.docker.internal` hostname, which is set via environment variables managed by [Vault + ESO](https://github.com/KristijanJ/ecommerce-shop-gitops).
