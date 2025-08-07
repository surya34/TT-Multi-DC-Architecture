/**
 * Management VPC Infrastructure - Production US-East-1
 * 
 * Purpose: Central management plane for multi-region infrastructure operations
 * Scale: Supporting 200+ microservices, 100M+ DAU, 5000+ deployments/day
 * 
 * Architecture Overview:
 * - AZ-A: Infrastructure as Code tools (Terraform, Ansible)
 * - AZ-B: GitOps and CI/CD platform (ArgoCD, GitHub Runners)
 * - AZ-C: Observability stack (Prometheus, Grafana, Loki)
 * 
 * Network Design:
 * - 3 public subnets (one per AZ) for NAT and load balancers
 * - 3 private subnets (one per AZ) for compute workloads
 * - Single NAT instance for cost optimization (can scale to NAT Gateway)
 */

locals {
    name_prefix = "${var.environment}-mgmt-vpc"
}

# Get current public IP for security group configuration

data "http" "my_ip" {
    url = "http://checkip.amazonaws.com" 

}

# vpc module

module "vpc" {
    source = "../../../modules/Networking/vpc"

    vpc_cidr = var.vpc_cidr
    availability_zones = var.availability_zones
    public_subnet_cidrs = var.public_subnet_cidrs
    private_subnet_cidrs = var.private_subnet_cidrs


    enable_dns_hostnames = true
    enable_dns_support   = true

    # VPC Flow Logs for compliance

    enable_flow_logs = var.enable_vpc_flow_logs 

    tags = {
        
        Name        = "${local.name_prefix}-vpc"
        Purpose     = "management-infrastructure"
        NetworkTier = "management"

    }

}