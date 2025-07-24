// ------------------------------------------------------------
//  Variables – Management VPC  ❙  Production ❙ us‑east‑1
// ------------------------------------------------------------

variable "aws_region" {
  description = "AWS region to deploy resources into"
  type        = string
  default     = "us-east-1"

  validation {
    condition     = can(regex("^us-[a-z]+-[0-9]+$", var.aws_region))
    error_message = "aws_region must be a valid AWS region, e.g. us-east-1."
  }
}

variable "environment" {
  description = "Deployment environment (e.g. dev, staging, prod)"
  type        = string
  default     = "production"
}

variable "vpc_cidr" {
  description = "CIDR block for the Management VPC"
  type        = string
  default     = "10.100.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "vpc_cidr must be a valid IPv4 CIDR block."
  }
}

variable "availability_zones" {
  description = "AWS AZs to use in this region"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (must match AZ count)"
  type        = list(string)
  default     = ["10.100.1.0/24", "10.100.2.0/24", "10.100.3.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (must match AZ count)"
  type        = list(string)
  default     = ["10.100.10.0/24", "10.100.11.0/24", "10.100.12.0/24"]
}

# Ensure subnet lists align with AZ list
locals {
  subnet_length_ok = (
    length(var.availability_zones) == length(var.public_subnet_cidrs) &&
    length(var.availability_zones) == length(var.private_subnet_cidrs)
  )
}

variable "key_pair_name" {
  description = "Existing EC2 key pair name for SSH access"
  type        = string
  default     = "mgmt-vpc-prod-key"
}

variable "enable_nat_gateway" {
  description = "true = use NAT Gateway, false = launch NAT instance (cost‑optimized)"
  type        = bool
  default     = false
}

variable "nat_instance_type" {
  description = "Instance type for NAT instance (used only if enable_nat_gateway = false)"
  type        = string
  default     = "t3.micro"
}

variable "instance_types" {
  description = "Instance types for DevOps, GitOps, Monitoring stacks"
  type        = map(string)
  default = {
    devops      = "t3.micro"
    gitops      = "t3.micro"
    monitoring  = "t3.micro"
  }
}

variable "monitoring_retention_days" {
  description = "Prometheus retention in days"
  type        = number
  default     = 7
}

variable "enable_vpc_flow_logs" {
  description = "Enable VPC Flow Logs for security/compliance"
  type        = bool
  default     = true
}

# ---------- Validations that span multiple variables ----------
validation "subnet_list_lengths" {
  condition     = local.subnet_length_ok
  error_message = "public_subnet_cidrs and private_subnet_cidrs must have the same length as availability_zones."
}

