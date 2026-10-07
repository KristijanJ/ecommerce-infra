# ============================================================================
# Environment Configuration
# Copy this file to terraform.tfvars and update with your values
# ============================================================================

# General
project_name = "ecommerce"
environment  = "prod"
profile      = "your-aws-sso-profile"

# VPC Configuration
region = "eu-central-1"
cidr   = "10.2.0.0/16"
azs = [
  "eu-central-1a",
  "eu-central-1b",
  "eu-central-1c"
]

private_subnets = [
  "10.2.1.0/24", # eu-central-1a
  "10.2.2.0/24", # eu-central-1b
  "10.2.3.0/24"  # eu-central-1c
]

public_subnets = [
  "10.2.11.0/24", # eu-central-1a
  "10.2.12.0/24", # eu-central-1b
  "10.2.13.0/24"  # eu-central-1c
]

database_subnets = [
  "10.2.21.0/24", # eu-central-1a
  "10.2.22.0/24", # eu-central-1b
  "10.2.23.0/24"  # eu-central-1c
]

enable_nat_gateway     = true
single_nat_gateway     = true # Set to false for high availability (more expensive)
one_nat_gateway_per_az = false
