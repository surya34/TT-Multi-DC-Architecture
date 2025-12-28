resource "aws_eks_node_group" "gpu" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "gpu-transcoding-ng"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.private_subnet_ids

  # Demo-friendly and reliable
  capacity_type  = "ON_DEMAND"
  instance_types = ["t3.micro"]  # cheap, widely available

  scaling_config {
    min_size     = 0
    max_size     = 1
    desired_size = 1
  }

  labels = {
    role        = "gpu-transcoding"
    accelerator = "gpu"
    workload    = "video"
  }

  taint {
    key    = "gpu"
    value  = "true"
    effect = "NO_SCHEDULE"
  }

  tags = merge(
    var.tags,
    {
      "NodeGroupType" = "gpu-demo"
      "CostProfile"  = "low"
    }
  )

}
