variable "node_role_arn" {
  description = "IAM role ARN used by EKS worker nodes"
  type        = string
}

variable "nat_management_role_arn" {
  description = "NAT admin role to perform eks operations"
  type        = string
}

