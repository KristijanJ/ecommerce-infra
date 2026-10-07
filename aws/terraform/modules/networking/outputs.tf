# ============================================================================
# VPC Outputs
# ============================================================================
output "vpc_id" {
  description = "The VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnets" {
  description = "The VPC public subnets"
  value       = module.vpc.public_subnets
}

output "private_subnets" {
  description = "The VPC private subnets"
  value       = module.vpc.private_subnets
}

output "database_subnets" {
  description = "The VPC database subnets"
  value       = module.vpc.database_subnets
}

output "database_subnet_group_name" {
  description = "The database subnet group name"
  value       = module.vpc.database_subnet_group_name
}
