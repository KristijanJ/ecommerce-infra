# ============================================================================
# Networking Module
# ============================================================================
module "networking" {
  source = "../../modules/networking"

  project_name = var.project_name
  environment  = var.environment

  cidr             = var.cidr
  azs              = var.azs
  private_subnets  = var.private_subnets
  public_subnets   = var.public_subnets
  database_subnets = var.database_subnets

  enable_nat_gateway     = var.enable_nat_gateway
  single_nat_gateway     = var.single_nat_gateway
  one_nat_gateway_per_az = var.one_nat_gateway_per_az

  profile = var.profile
  region  = var.region
}

module "eks" {
  source = "../../modules/eks"

  project_name = var.project_name
  environment  = var.environment

  vpc_id     = module.networking.vpc_id
  subnet_ids = module.networking.public_subnets

  worker_node_desired_size = "3"
  worker_node_disk_size    = "20"
  worker_node_max_size     = "3"
  worker_node_min_size     = "3"
  eks_instance_types       = ["t3.medium"]
}

module "rds" {
  source = "../../modules/rds"

  project_name = var.project_name
  environment  = var.environment

  vpc_id                     = module.networking.vpc_id
  database_subnet_group_name = module.networking.database_subnet_group_name
  node_security_group_id     = module.eks.node_security_group_id
}

# ============================================================================
# JWT secret (read by the frontend and backend through External Secrets)
# ============================================================================
resource "random_password" "jwt" {
  length  = 64
  special = false
}

resource "aws_secretsmanager_secret" "jwt" {
  name        = "/${var.project_name}/${var.environment}/jwt"
  description = "JWT signing secret shared by the frontend and backend"

  # The stack is destroyed every session. Without this, the name stays reserved for 7 days
  # after deletion and the next apply fails with "already scheduled for deletion".
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "jwt" {
  secret_id = aws_secretsmanager_secret.jwt.id

  # The key matches the Vault secret/jwt key used on the homelab.
  secret_string = jsonencode({
    "jwt-secret" = random_password.jwt.result
  })
}
