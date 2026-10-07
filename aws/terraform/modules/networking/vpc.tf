module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.7"

  name = "${var.project_name}-vpc-${var.environment}"
  cidr = var.cidr
  azs  = var.azs

  private_subnets  = var.private_subnets
  public_subnets   = var.public_subnets
  database_subnets = var.database_subnets

  enable_nat_gateway     = var.enable_nat_gateway
  single_nat_gateway     = var.single_nat_gateway
  one_nat_gateway_per_az = var.one_nat_gateway_per_az

  map_public_ip_on_launch = true

  # Tags required for AWS Load Balancer Controller
  public_subnet_tags = {
    "kubernetes.io/role/elb"                                               = "1"
    "kubernetes.io/cluster/${var.project_name}-cluster-${var.environment}" = "shared"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"                                      = "1"
    "kubernetes.io/cluster/${var.project_name}-cluster-${var.environment}" = "shared"
  }
}
