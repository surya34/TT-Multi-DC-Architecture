resource "kubernetes_config_map_v1" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = yamlencode([
      {
        rolearn = var.node_role_arn
        username = "system:node:{{EC2PrivateDNSName}}"
        groups = [
          "system:bootstrappers",
          "system:nodes"
        ]
      },
      # Item 2: The NAT Instance (Admin permissions)
      {
        rolearn  = var.nat_management_role_arn
        username = "nat-admin"
        groups   = [
          "system:masters" # Gives your NAT instance full admin rights
        ]
      }
    ])
  }
}

