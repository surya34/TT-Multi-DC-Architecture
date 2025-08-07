# terraform/modules/networking/vpc/versions.tf

/**
 * Provider Requirements for VPC Module
 * 
 * Ensures consistent provider versions across module usage
 */

terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0, < 6.0.0"
    }
  }
}