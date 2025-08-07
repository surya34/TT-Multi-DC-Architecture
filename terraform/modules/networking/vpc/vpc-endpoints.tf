# terraform/modules/networking/vpc/vpc-endpoints.tf

/**
 * VPC Endpoints Configuration
 * 
 * Creates VPC endpoints to reduce data transfer costs and improve security
 */

# S3 Gateway Endpoint
resource "aws_vpc_endpoint" "s3" {
  count = var.enable_s3_endpoint ? 1 : 0
  
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${data.aws_region.current.name}.s3"
  
  route_table_ids = concat(
    [aws_route_table.public.id],
    aws_route_table.private[*].id,
    var.create_database_subnets ? [aws_route_table.database[0].id] : []
  )
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = "*"
        Resource  = "*"
      }
    ]
  })
  
  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-s3-endpoint"
      Type = "gateway"
    }
  )
}

# DynamoDB Gateway Endpoint
resource "aws_vpc_endpoint" "dynamodb" {
  count = var.enable_dynamodb_endpoint ? 1 : 0
  
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${data.aws_region.current.name}.dynamodb"
  
  route_table_ids = concat(
    [aws_route_table.public.id],
    aws_route_table.private[*].id,
    var.create_database_subnets ? [aws_route_table.database[0].id] : []
  )
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = "*"
        Resource  = "*"
      }
    ]
  })
  
  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-dynamodb-endpoint"
      Type = "gateway"
    }
  )
}

# EC2 Interface Endpoint
resource "aws_vpc_endpoint" "ec2" {
  count = var.enable_ec2_endpoint ? 1 : 0
  
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ec2"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = length(var.endpoint_security_group_ids) > 0 ? var.endpoint_security_group_ids : [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true
  
  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-ec2-endpoint"
      Type = "interface"
    }
  )
}

# Systems Manager Endpoints
resource "aws_vpc_endpoint" "ssm" {
  count = var.enable_ssm_endpoints ? 1 : 0
  
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = length(var.endpoint_security_group_ids) > 0 ? var.endpoint_security_group_ids : [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true
  
  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-ssm-endpoint"
      Type = "interface"
    }
  )
}

resource "aws_vpc_endpoint" "ssm_messages" {
  count = var.enable_ssm_endpoints ? 1 : 0
  
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = length(var.endpoint_security_group_ids) > 0 ? var.endpoint_security_group_ids : [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true
  
  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-ssm-messages-endpoint"
      Type = "interface"
    }
  )
}

resource "aws_vpc_endpoint" "ec2_messages" {
  count = var.enable_ssm_endpoints ? 1 : 0
  
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = length(var.endpoint_security_group_ids) > 0 ? var.endpoint_security_group_ids : [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true
  
  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-ec2-messages-endpoint"
      Type = "interface"
    }
  )
}

# Security Group for VPC Endpoints
resource "aws_security_group" "vpc_endpoints" {
  count = (var.enable_ec2_endpoint || var.enable_ssm_endpoints) && length(var.endpoint_security_group_ids) == 0 ? 1 : 0
  
  name        = "${var.name_prefix}-vpc-endpoints-sg"
  description = "Security group for VPC endpoints"
  vpc_id      = aws_vpc.main.id
  
  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
  
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-vpc-endpoints-sg"
    }
  )
}