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

variable "cidr" {
  description = "CIDR block for the VPC (e.g., 10.0.0.0/16)"
  type        = string
}

variable "azs" {
  description = "List of availability zones for the VPC subnets"
  type        = list(string)
}

variable "private_subnets" {
  description = "List of CIDR blocks for private subnets"
  type        = list(string)
}

variable "public_subnets" {
  description = "List of CIDR blocks for public subnets"
  type        = list(string)
}

variable "database_subnets" {
  description = "List of CIDR blocks for database subnets"
  type        = list(string)
}

variable "enable_nat_gateway" {
  description = "Enable NAT gateway for private subnets"
  type        = bool
  default     = false
}

variable "single_nat_gateway" {
  description = "Use a single NAT gateway for all private subnets (less expensive than one per AZ)"
  type        = bool
  default     = true
}

variable "one_nat_gateway_per_az" {
  description = "Create one NAT gateway per availability zone (most expensive but highly available)"
  type        = bool
  default     = false
}
