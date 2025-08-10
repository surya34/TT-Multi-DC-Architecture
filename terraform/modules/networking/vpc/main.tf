# terraform/modules/networking/vpc/main.tf

/**
 * VPC Module - Enterprise Management VPC
 * 
 * Creates a production-grade VPC with:
 * - Multi-AZ architecture across 3 availability zones
 * - Public and private subnets per AZ
 * - Internet Gateway for public subnet connectivity
 * - Elastic IP for NAT instance
 * - Custom route tables per subnet type
 * - VPC Endpoints for AWS services
 */

# Data source for current region
data "aws_region" "current" {}

# Data source for available AZs
data "aws_availability_zones" "available" {
  state = "available"
  
  # Exclude Local Zones and Wavelength Zones
  filter {
    name   = "zone-type"
    values = ["availability-zone"]
  }
}

# Main VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support
  
  # Enable IPv6 if requested
  assign_generated_ipv6_cidr_block = var.enable_ipv6
  
  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-vpc"
      Type = "management"
    }
  )
  # Add this lifecycle block to ignore tags that are automatically added by AWS.
  lifecycle {
    ignore_changes = [
      tags_all,
    ]
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  
  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-igw"
    }
  )
}

# Elastic IP for NAT Instance
resource "aws_eip" "nat" {
  count  = var.create_nat_instance ? 1 : 0
  domain = "vpc"
  
  tags = merge(
    var.tags,
    {
      Name    = "${var.name_prefix}-nat-eip"
      Purpose = "nat-instance"
    }
  )
  
  depends_on = [aws_internet_gateway.main]
}

# Public Subnets (one per AZ)
resource "aws_subnet" "public" {
  count = length(var.availability_zones)
  
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = var.map_public_ip_on_launch
  
  # IPv6 support
  ipv6_cidr_block                 = var.enable_ipv6 ? cidrsubnet(aws_vpc.main.ipv6_cidr_block, 8, count.index) : null
  assign_ipv6_address_on_creation = var.enable_ipv6
  
  tags = merge(
    var.tags,
    {
      Name                     = "${var.name_prefix}-public-${var.availability_zones[count.index]}"
      Type                     = "public"
      Tier                     = "public"
      "kubernetes.io/role/elb" = "1"  # For future EKS integration
      AZ                       = var.availability_zones[count.index]
    }
  )
}

# Private Subnets (one per AZ)
resource "aws_subnet" "private" {
  count = length(var.availability_zones)
  
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]
  
  # IPv6 support
  ipv6_cidr_block                 = var.enable_ipv6 ? cidrsubnet(aws_vpc.main.ipv6_cidr_block, 8, count.index + 3) : null
  assign_ipv6_address_on_creation = var.enable_ipv6
  
  tags = merge(
    var.tags,
    {
      Name                              = "${var.name_prefix}-private-${var.availability_zones[count.index]}"
      Type                              = "private"
      Tier                              = "private"
      "kubernetes.io/role/internal-elb" = "1"  # For future EKS integration
      AZ                                = var.availability_zones[count.index]
    }
  )
}

# Database Subnets (optional, for RDS subnet groups)
resource "aws_subnet" "database" {
  count = var.create_database_subnets ? length(var.availability_zones) : 0
  
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.database_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]
  
  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-database-${var.availability_zones[count.index]}"
      Type = "database"
      Tier = "data"
      AZ   = var.availability_zones[count.index]
    }
  )
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  
  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-public-rt"
      Type = "public"
    }
  )
}

# Public Route to Internet Gateway
resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

# IPv6 route for public subnets
resource "aws_route" "public_internet_ipv6" {
  count = var.enable_ipv6 ? 1 : 0
  
  route_table_id              = aws_route_table.public.id
  destination_ipv6_cidr_block = "::/0"
  gateway_id                  = aws_internet_gateway.main.id
}

# Associate public subnets with public route table
resource "aws_route_table_association" "public" {
  count = length(var.availability_zones)
  
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Private Route Tables (one per AZ for isolation)
resource "aws_route_table" "private" {
  count = length(var.availability_zones)
  
  vpc_id = aws_vpc.main.id
  
  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-private-rt-${var.availability_zones[count.index]}"
      Type = "private"
      AZ   = var.availability_zones[count.index]
    }
  )
}

# Associate private subnets with their route tables
resource "aws_route_table_association" "private" {
  count = length(var.availability_zones)
  
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# Database route table (if database subnets are created)
resource "aws_route_table" "database" {
  count = var.create_database_subnets ? 1 : 0
  
  vpc_id = aws_vpc.main.id
  
  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-database-rt"
      Type = "database"
    }
  )
}

# Associate database subnets with database route table

resource "aws_route_table_association" "database" {
  count = var.create_database_subnets ? length(var.availability_zones) : 0
  
  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database[0].id
}

# DHCP Options Set (optional)
resource "aws_vpc_dhcp_options" "main" {
  count = var.enable_custom_dhcp_options ? 1 : 0
  
  domain_name          = var.enable_custom_dhcp_options
  domain_name_servers  = var.dhcp_options_domain_name_servers
  ntp_servers          = var.dhcp_options_ntp_servers
  netbios_name_servers = var.dhcp_options_netbios_name_servers
  netbios_node_type    = var.dhcp_options_netbios_node_type
  
  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-dhcp-options"
    }
  )
}

# Associate DHCP Options with VPC
resource "aws_vpc_dhcp_options_association" "main" {
  count = var.enable_custom_dhcp_options ? 1 : 0
  
  vpc_id          = aws_vpc.main.id
  dhcp_options_id = aws_vpc_dhcp_options.main[0].id
}

# Default Security Group rules (restrict all)
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.main.id
  
  # Remove all rules from default SG
  # Force explicit security group usage
  
  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-default-sg-do-not-use"
      Note = "Default SG - No rules allowed"
    }
  )
}

# Default Network ACL
resource "aws_default_network_acl" "default" {
  default_network_acl_id = aws_vpc.main.default_network_acl_id
  
  # Allow all traffic by default
  # Security groups provide the actual security
  
  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
  
  ingress {
    protocol        = -1
    rule_no         = 101
    action          = "allow"
    ipv6_cidr_block = "::/0"
    from_port       = 0
    to_port         = 0
  }
  
  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
  
  egress {
    protocol        = -1
    rule_no         = 101
    action          = "allow"
    ipv6_cidr_block = "::/0"
    from_port       = 0
    to_port         = 0
  }
  
  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-default-nacl"
    }
  )
}