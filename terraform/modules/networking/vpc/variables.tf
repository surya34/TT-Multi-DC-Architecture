# terraform/modules/networking/vpc/variables.tf

/**
 * VPC Module Variables
 * 
 * Configurable parameters for VPC creation
 */

# Naming and Tagging
variable "name_prefix" {
  description = "Prefix for resource naming"
  type        = string
  
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.name_prefix))
    error_message = "Name prefix must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}

# Network Configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  
  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "At least 2 availability zones must be specified for high availability."
  }
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (must match number of AZs)"
  type        = list(string)
  
  # Can only validate this variable itself
  validation {
    condition     = length(var.public_subnet_cidrs) >= 2 && length(var.public_subnet_cidrs) <= 6
    error_message = "Between 2 and 6 public subnet CIDRs must be specified."
  }
  
  validation {
    condition     = alltrue([for cidr in var.public_subnet_cidrs : can(cidrhost(cidr, 0))])
    error_message = "All public subnet CIDRs must be valid IPv4 CIDR blocks."
  }
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (must match number of AZs)"
  type        = list(string)
  
  # Can only validate this variable itself
  validation {
    condition     = length(var.private_subnet_cidrs) >= 2 && length(var.private_subnet_cidrs) <= 6
    error_message = "Between 2 and 6 private subnet CIDRs must be specified."
  }
  
  validation {
    condition     = alltrue([for cidr in var.private_subnet_cidrs : can(cidrhost(cidr, 0))])
    error_message = "All private subnet CIDRs must be valid IPv4 CIDR blocks."
  }
}

variable "database_subnet_cidrs" {
  description = "CIDR blocks for database subnets (must match number of AZs)"
  type        = list(string)
}

variable "create_nat_instance" {
  type    = bool
  default = true
}

variable "nat_ami_id" {
  type = string
  description = "AMI ID for NAT instance (Amazon Linux 2 NAT AMI)"
}

variable "nat_instance_type" {
  type    = string
  default = "t3.micro"
}

variable "key_name" {
  type = string
  description = "SSH key for NAT instance"
}


# VPC Features
variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in VPC"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Enable DNS support in VPC"
  type        = bool
  default     = true
}

variable "enable_ipv6" {
  description = "Enable IPv6 for VPC"
  type        = bool
  default     = false
}

variable "map_public_ip_on_launch" {
  description = "Map public IP on launch for public subnets"
  type        = bool
  default     = true
}

# Subnet Features
variable "create_database_subnets" {
  description = "Create dedicated database subnets"
  type        = bool
  default     = false
}

# DHCP Options
variable "enable_custom_dhcp_options" {
  description = "Enable custom DHCP options set"
  type        = bool
  default     = false
}

variable "dhcp_options_domain_name" {
  description = "Domain name for DHCP options set"
  type        = string
  default     = ""
}

variable "dhcp_options_domain_name_servers" {
  description = "Domain name servers for DHCP options set"
  type        = list(string)
  default     = ["AmazonProvidedDNS"]
}

variable "dhcp_options_ntp_servers" {
  description = "NTP servers for DHCP options set"
  type        = list(string)
  default     = []
}

variable "dhcp_options_netbios_name_servers" {
  description = "NetBIOS name servers for DHCP options set"
  type        = list(string)
  default     = []
}

variable "dhcp_options_netbios_node_type" {
  description = "NetBIOS node type for DHCP options set"
  type        = number
  default     = 2
}

# VPC Flow Logs
variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs"
  type        = bool
  default     = false
}


variable "flow_logs_destination_type" {
  description = "flow logs destination"
  type        = string
  default     =  "s3"
}

variable "flow_logs_retention_days" {
  description = "VPC Flow Logs retention in days"
  type        = number
  default     = 90
}

variable "flow_logs_traffic_type" {
  description = "Type of traffic to capture in flow logs"
  type        = string
  default     = "ALL"
  
  validation {
    condition     = contains(["ALL", "ACCEPT", "REJECT"], var.flow_logs_traffic_type)
    error_message = "Flow logs traffic type must be ALL, ACCEPT, or REJECT."
  }
}

# VPC Endpoints
variable "enable_s3_endpoint" {
  description = "Create VPC endpoint for S3"
  type        = bool
  default     = true
}

variable "enable_dynamodb_endpoint" {
  description = "Create VPC endpoint for DynamoDB"
  type        = bool
  default     = true
}

variable "enable_ec2_endpoint" {
  description = "Create VPC endpoint for EC2"
  type        = bool
  default     = false
}

variable "enable_ssm_endpoints" {
  description = "Create VPC endpoints for Systems Manager"
  type        = bool
  default     = false
}

variable "endpoint_security_group_ids" {
  description = "Security group IDs for interface endpoints"
  type        = list(string)
  default     = []
}