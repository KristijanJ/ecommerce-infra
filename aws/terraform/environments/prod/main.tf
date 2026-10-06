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

  worker_node_desired_size = "2"
  worker_node_disk_size    = "20"
  worker_node_max_size     = "3"
  worker_node_min_size     = "2"
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
