# ============================================================================
# General Configuration
# ============================================================================
variable "environment" {
  description = "The environment (dev, staging, prod)"
  default     = "prod"
}

variable "region" {
  description = "The aws region"
  default     = "eu-central-1"
}

variable "profile" {
  description = "The AWS SSO profile"
  default     = null
  nullable    = true
}

variable "project_name" {
  description = "The name of the project"
  default     = "ecommerce"
}

# ============================================================================
# VPC Configuration
# ============================================================================
variable "cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "azs" {
  description = "List of availability zones"
  type        = list(string)
}

variable "private_subnets" {
  description = "List of private subnet CIDR blocks"
  type        = list(string)
}

variable "public_subnets" {
  description = "List of public subnet CIDR blocks"
  type        = list(string)
}

variable "database_subnets" {
  description = "List of database subnet CIDR blocks for RDS"
  type        = list(string)
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway for all private subnets"
  type        = bool
  default     = true
}

variable "one_nat_gateway_per_az" {
  description = "Create one NAT Gateway per availability zone"
  type        = bool
  default     = false
}
