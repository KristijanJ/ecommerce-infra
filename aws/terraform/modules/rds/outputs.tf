output "db_instance_address" {
  description = "Hostname of the RDS instance (use as DB_HOST)"
  value       = module.db.db_instance_address
}

output "db_instance_port" {
  description = "Port of the RDS instance"
  value       = module.db.db_instance_port
}

output "db_instance_name" {
  description = "Name of the initial database"
  value       = module.db.db_instance_name
}

output "db_instance_username" {
  description = "Master username"
  value       = module.db.db_instance_username
  sensitive   = true
}

output "db_instance_master_user_secret_arn" {
  description = "ARN of the Secrets Manager secret that holds the master password"
  value       = module.db.db_instance_master_user_secret_arn
}

output "security_group_id" {
  description = "Security group ID of the database"
  value       = aws_security_group.rds.id
}
