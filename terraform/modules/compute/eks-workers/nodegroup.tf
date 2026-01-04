resource "aws_eks_node_group" "system" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "system-ng"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.private_subnet_ids

  capacity_type  = "ON_DEMAND"

  # Use inexpensive demo instance
  instance_types = ["t3.small"]

  scaling_config {
    min_size     = 1
    max_size     = 1
    desired_size = 1
  }

  labels = {
    role = "system"
  }

}
