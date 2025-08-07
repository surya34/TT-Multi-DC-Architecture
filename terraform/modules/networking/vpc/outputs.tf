# terraform/modules/networking/vpc/outputs.tf

/**
 * VPC Module Outputs
 * 
 * Exports VPC resource IDs and attributes for use by other modules
 */

# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_arn" {
  description = "ARN of the VPC"
  value       = aws_vpc.main.arn
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "vpc_ipv6_cidr" {
  description = "IPv6 CIDR block of the VPC"
  value       = try(aws_vpc.main.ipv6_cidr_block, null)
}

output "vpc_owner_id" {
  description = "Owner ID of the VPC"
  value       = aws_vpc.main.owner_id
}

# Internet Gateway
output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "internet_gateway_arn" {
  description = "ARN of the Internet Gateway"
  value       = aws_internet_gateway.main.arn
}

# Subnet Outputs
output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "database_subnet_ids" {
  description = "List of database subnet IDs"
  value       = try(aws_subnet.database[*].id, [])
}

output "public_subnet_arns" {
  description = "List of public subnet ARNs"
  value       = aws_subnet.public[*].arn
}

output "private_subnet_arns" {
  description = "List of private subnet ARNs"
  value       = aws_subnet.private[*].arn
}

output "public_subnet_cidrs" {
  description = "List of public subnet CIDR blocks"
  value       = aws_subnet.public[*].cidr_block
}

output "private_subnet_cidrs" {
  description = "List of private subnet CIDR blocks"
  value       = aws_subnet.private[*].cidr_block
}

output "database_subnet_cidrs" {
  description = "List of database subnet CIDR blocks"
  value       = try(aws_subnet.database[*].cidr_block, [])
}

# Route Table Outputs
output "public_route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.public.id
}

output "private_route_table_ids" {
  description = "List of private route table IDs"
  value       = aws_route_table.private[*].id
}

output "database_route_table_id" {
  description = "ID of the database route table"
  value       = try(aws_route_table.database[0].id, null)
}

# NAT EIP Outputs
output "nat_eip_id" {
  description = "Allocation ID of the NAT Elastic IP"
  value       = try(aws_eip.nat[0].id, null)
}

output "nat_eip_public_ip" {
  description = "Public IP address of the NAT Elastic IP"
  value       = try(aws_eip.nat[0].public_ip, null)
}

# Availability Zones
output "availability_zones" {
  description = "List of availability zones used"
  value       = var.availability_zones
}

# VPC Endpoints (if created)
output "vpc_endpoint_s3_id" {
  description = "ID of the S3 VPC endpoint"
  value       = try(aws_vpc_endpoint.s3[0].id, null)
}

output "vpc_endpoint_dynamodb_id" {
  description = "ID of the DynamoDB VPC endpoint"
  value       = try(aws_vpc_endpoint.dynamodb[0].id, null)
}

# Subnet Groups (for RDS, ElastiCache, etc.)
output "public_subnet_group" {
  description = "Map of public subnet IDs by AZ"
  value = {
    for idx, subnet in aws_subnet.public :
    var.availability_zones[idx] => subnet.id
  }
}

output "private_subnet_group" {
  description = "Map of private subnet IDs by AZ"
  value = {
    for idx, subnet in aws_subnet.private :
    var.availability_zones[idx] => subnet.id
  }
}

# Flow Logs
output "flow_log_id" {
  description = "ID of the VPC Flow Log"
  value       = try(aws_flow_log.main[0].id, null)
}

output "flow_log_group_name" {
  description = "Name of the CloudWatch log group for flow logs"
  value       = try(aws_cloudwatch_log_group.flow_logs[0].name, null)
}

# DHCP Options
output "dhcp_options_id" {
  description = "ID of the DHCP options set"
  value       = try(aws_vpc_dhcp_options.main[0].id, aws_vpc.main.dhcp_options_id)
}

# Summary Output
output "vpc_summary" {
  description = "Summary of VPC configuration"
  value = {
    vpc_id               = aws_vpc.main.id
    vpc_cidr             = aws_vpc.main.cidr_block
    region               = data.aws_region.current.name
    availability_zones   = var.availability_zones
    public_subnets       = length(aws_subnet.public)
    private_subnets      = length(aws_subnet.private)
    database_subnets     = length(try(aws_subnet.database, []))
    flow_logs_enabled    = var.enable_flow_logs
    endpoints_enabled    = {
      s3       = var.enable_s3_endpoint
      dynamodb = var.enable_dynamodb_endpoint
    }
  }
}