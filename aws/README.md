# AWS Terraform

Terraform for the aws-prod environment of the ecommerce shop: a VPC, an EKS cluster, an RDS PostgreSQL database and the secrets the apps read. What runs inside the cluster is defined in the [gitops repo](https://github.com/KristijanJ/ecommerce-shop-gitops).

## What it creates

| Module       | Resources                                                                                      |
| ------------ | ---------------------------------------------------------------------------------------------- |
| `networking` | VPC with public, private and database subnets, tagged for the AWS Load Balancer Controller      |
| `eks`        | EKS cluster `ecommerce-cluster-prod`, a managed node group, add-ons, IAM roles, the AWS Load Balancer Controller |
| `rds`        | RDS PostgreSQL 18, a security group that allows port 5432 only from the node security group, the connection secret |

The environment's `main.tf` also creates the JWT signing secret.

### EKS

- Kubernetes 1.36, built with the `terraform-aws-modules/eks` module. EKS Auto Mode is off.
- One managed node group of three `t3.medium` nodes (20 GB disks) in the public subnets.
- Add-ons: CoreDNS, kube-proxy, the Pod Identity agent, the VPC CNI and the EBS CSI driver. The VPC CNI and the EBS CSI driver get their IAM roles through Pod Identity.
- The cluster endpoint is public. The identity that runs `terraform apply` gets cluster admin access.
- The AWS Load Balancer Controller is installed as a Helm chart through the `eks-blueprints-addons` module. The EBS CSI driver and this controller are needed later to delete volumes and load balancers when the stack is torn down.
- An IAM role for External Secrets is bound to the `external-secrets` service account in the `external-secrets` namespace through a Pod Identity association. Its policy reads Secrets Manager and SSM parameters.

### RDS

- Instance class `db.t3.small`, 20 GB of gp3 storage, database `ecommerce`, user `ecommerce_admin`.
- Not publicly accessible. It lives in the database subnet group.
- Terraform generates the master password and writes the connection details to the Secrets Manager secret `/ecommerce/prod/db` with the keys `db-host`, `db-port`, `db-user`, `db-pass` and `db-database`.
- `rds.force_ssl` is off because the backend does not connect with SSL yet.

### Secrets

| Secret                  | Content                                   |
| ----------------------- | ----------------------------------------- |
| `/ecommerce/prod/db`    | Database connection details               |
| `/ecommerce/prod/jwt`   | JWT signing secret, key `jwt-secret`      |

Both secrets are created with `recovery_window_in_days = 0`. The stack is destroyed after every session, and a recovery window would keep the names reserved and fail the next apply.

## Prerequisites

- Terraform `~> 1.16`
- AWS CLI with an SSO profile for the account
- `kubectl`
- Access to the state bucket `ecommerce-terraform-state-jov` (S3 backend, `eu-central-1`, lock file instead of DynamoDB)

## Configuration

Copy the example variables and set your SSO profile:

```bash
cp aws/terraform/environments/prod/terraform.example.tfvars aws/terraform/environments/prod/terraform.tfvars
```

`terraform.tfvars` is gitignored. The example holds the region (`eu-central-1`), the VPC CIDR `10.2.0.0/16`, three availability zones, the subnet ranges and the NAT gateway settings.

## Usage

Log in first:

```bash
aws sso login --profile <profile>
```

Run these from the root of the infra repo. Each target asks for the environment name (`prod`).

```bash
make aws-tf-init        # asks for the SSO profile, passes it to the S3 backend
make aws-tf-plan
make aws-tf-apply
```

After the apply, point kubectl at the cluster:

```bash
aws eks update-kubeconfig --name ecommerce-cluster-prod --region eu-central-1 --profile <profile>
```

Then run `make start-aws-prod` in the gitops repo. It installs ArgoCD and the apps, creates the DNS records and seeds the database.

Other targets:

```bash
make aws-tf-fmt         # terraform fmt -recursive
make aws-tf-validate
```

## Tearing down

1. In the gitops repo, run `make teardown-aws-prod`. It removes the DNS records and everything ArgoCD deployed, and waits until the load balancers and EBS volumes are gone.
2. In this repo, run `make aws-tf-destroy`.

If you skip the first step, the load balancers and volumes that the cluster created stay behind. They block the VPC deletion and keep costing money.

## Cost

The cluster is meant to run for a few hours. While it is up it bills for the EKS control plane, three nodes, the RDS instance, the load balancer and, if the NAT gateway is on, the NAT gateway. Destroy it when the session ends.
