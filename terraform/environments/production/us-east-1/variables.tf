# terraform/environments/production/us-east-1/variables.tf

/**
 * Variables - Management VPC Production US-East-1
 * 
 * Production best practice: No hardcoded defaults for environment-specific values
 * Defaults only for truly universal constants
 */

# Core Configuration - No defaults (environment-specific)
variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  # No default - must be explicitly set per environment
}

variable "environment" {
  description = "Environment name (production/staging/development)"
  type        = string
  # No default - prevents accidental deployment to wrong environment
  
  validation {
    condition     = contains(["production", "staging", "development"], var.environment)
    error_message = "Environment must be production, staging, or development."
  }
}

variable "aws_account_id" {
  description = "AWS Account ID for environment"
  type        = string
  # No default - must match the target account
  
  validation {
    condition     = can(regex("^[0-9]{12}$", var.aws_account_id))
    error_message = "AWS Account ID must be 12 digits."
  }
}

# Network Configuration - No defaults (architecture decisions)
variable "vpc_cidr" {
  description = "CIDR block for Management VPC"
  type        = string
  # No default - each environment needs different CIDR
}

variable "availability_zones" {
  description = "List of availability zones to use"
  type        = list(string)
  # No default - region-specific
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  # No default - must align with VPC CIDR
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  # No default - must align with VPC CIDR
}

# Security Configuration - Sensitive, no defaults
variable "key_pair_name" {
  description = "EC2 Key pair name for SSH access"
  type        = string
  sensitive   = true  # Marks as sensitive in logs
  # No default - security best practice
}

variable "allowed_ssh_cidrs" {
  description = "CIDR blocks allowed to SSH to bastion"
  type        = list(string)
  sensitive   = true
  default     = []  # Empty default is safe
}

# Cost Optimization Flags - Defaults make sense here
variable "enable_nat_gateway" {
  description = "Use NAT Gateway (true) or NAT Instance (false)"
  type        = bool
  default     = false  # NAT instance is our cost-optimized default
}

variable "enable_vpc_flow_logs" {
  description = "Enable VPC Flow Logs for security compliance"
  type        = bool
  default     = true  # Security by default
}

# Instance Types - No defaults (cost implications)
variable "instance_types" {
  description = "Instance types for each component"
  type = object({
    nat        = string
    devops     = string
    gitops     = string
    monitoring = string
  })
  # No default - pricing varies by region/environment
}

# Scaling Configuration - No defaults (workload-specific)
variable "auto_scaling_config" {
  description = "Auto-scaling configuration for instance groups"
  type = object({
    devops_min     = number
    devops_max     = number
    devops_desired = number
    gitops_min     = number
    gitops_max     = number
    gitops_desired = number
  })
  # No default - depends on workload
}

# Monitoring Configuration
variable "monitoring_retention_days" {
  description = "Prometheus retention in days"
  type        = number
  # No default - cost/compliance implications
}

variable "backup_retention_days" {
  description = "Backup retention period in days"
  type        = number
  # No default - compliance requirement
}

# Tagging Strategy - Some defaults acceptable
variable "mandatory_tags" {
  description = "Mandatory tags for all resources"
  type        = map(string)
  # No default - organization-specific
}

variable "cost_center" {
  description = "Cost center for billing"
  type        = string
  # No default - department-specific
}

variable "data_classification" {
  description = "Data classification level"
  type        = string
  default     = "internal"  # Safe default
  
  validation {
    condition     = contains(["public", "internal", "confidential", "restricted"], var.data_classification)
    error_message = "Data classification must be public, internal, confidential, or restricted."
  }
}

# Feature Flags
variable "enable_enhanced_monitoring" {
  description = "Enable enhanced CloudWatch monitoring"
  type        = bool
  default     = false  # Cost consideration
}

variable "enable_auto_shutdown" {
  description = "Enable automatic shutdown of non-critical instances"
  type        = bool
  default     = false  # Explicit opt-in
}

# Disaster Recovery
variable "dr_region" {
  description = "Disaster recovery region"
  type        = string
  # No default - must be explicitly chosen
}

variable "enable_cross_region_backup" {
  description = "Enable cross-region backup"
  type        = bool
  default     = false  # Cost consideration
}