# 1. Trust Policy: Allows EC2 instances to assume this role
resource "aws_iam_role" "nat_management" {
  name = "${var.name_prefix}-nat-management-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# 2. Permissions Policy: Allows describing the EKS cluster
resource "aws_iam_role_policy" "eks_describe" {
  name = "${var.name_prefix}-eks-describe-policy"
  role = aws_iam_role.nat_management.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "eks:DescribeCluster",
          "eks:ListClusters",
          "eks:AccessKubernetesApi" # Useful for newer EKS access modes
        ]
        Resource = "*" # Or specify your cluster ARN for better security
      }
    ]
  })
}

# 3. Instance Profile: The bridge between IAM and EC2
resource "aws_iam_instance_profile" "nat_profile" {
  name = "${var.name_prefix}-nat-instance-profile"
  role = aws_iam_role.nat_management.name
}
