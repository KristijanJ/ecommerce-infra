variable "environment" {
  description = "Environment name (dev/staging/prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "The name of the project"
  default     = "ecommerce"
}

variable "vpc_id" {
  description = "The VPC ID where the EKS cluster will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "A list of subnet IDs for the EKS cluster"
  type        = list(string)
}

variable "eks_instance_types" {
  description = "A list of instance types for the EKS worker nodes"
  type        = list(string)
}

variable "worker_node_desired_size" {
  description = "The desired number of EKS worker nodes"
  type        = number
}

variable "worker_node_min_size" {
  description = "The minimum number of EKS worker nodes"
  type        = number
}

variable "worker_node_max_size" {
  description = "The maximum number of EKS worker nodes"
  type        = number
}

variable "worker_node_disk_size" {
  description = "The disk size (in GB) for each EKS worker node"
  type        = number
}
