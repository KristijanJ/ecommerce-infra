variable "environment" {
  description = "Environment name (dev/staging/prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "The name of the project"
  type        = string
  default     = "ecommerce"
}

variable "vpc_id" {
  description = "The VPC ID where the database security group is created"
  type        = string
}

variable "database_subnet_group_name" {
  description = "Name of the existing DB subnet group (created by the networking module)"
  type        = string
}

variable "node_security_group_id" {
  description = "Security group ID of the EKS nodes, allowed to connect to the database"
  type        = string
}

variable "instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.small"
}

variable "allocated_storage" {
  description = "Allocated storage in GiB"
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Name of the initial database"
  type        = string
  default     = "ecommerce"
}

variable "username" {
  description = "Master username (the password is generated and stored in Secrets Manager)"
  type        = string
  default     = "ecommerce_admin"
}
