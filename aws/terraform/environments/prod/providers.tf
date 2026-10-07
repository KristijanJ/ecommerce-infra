terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.67"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.9"
    }
  }

  backend "s3" {
    bucket       = "ecommerce-terraform-state-jov"
    key          = "environment/prod/terraform.tfstate"
    region       = "eu-central-1"
    use_lockfile = true
  }

  required_version = "~> 1.16"
}

provider "aws" {
  region  = var.region
  profile = var.profile

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
    }
  }
}

# CloudFront resources (including WAF) must be created in us-east-1
provider "aws" {
  alias   = "us_east_1"
  region  = "us-east-1"
  profile = var.profile

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
    }
  }
}

# Data source for EKS cluster authentication
data "aws_eks_cluster_auth" "cluster_auth" {
  name = module.eks.cluster_name
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.cluster_auth.token
}

provider "helm" {
  kubernetes = {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.cluster_auth.token
  }
}
