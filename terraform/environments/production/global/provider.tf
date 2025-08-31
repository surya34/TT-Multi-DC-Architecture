/**
 * Provider Configuration - Management VPC Production
 * 
 * Configures AWS provider with enterprise defaults and tagging strategy
 */

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.4"
    }
  }
}

provider "aws" {
  region = var.aws_region

  # Enterprise tagging strategy
  default_tags {
    tags = {
      Environment        = var.environment
      Project            = "management-vpc"
      ManagedBy          = "terraform"
      CostCenter         = "platform-engineering"
      DataClassification = "internal"
      Compliance         = "soc2-pci"
      BackupPolicy       = "daily"
      DisasterRecovery   = "multi-region"
      LastUpdated        = timestamp()
    }
  }

  ignore_tags {
    keys = ["BackupPolicy", "Compliance", "CostCenter", "DataClassification", "DisasterRecovery", "Environment", "LastUpdated", "ManagedBy", "Project", ""]
  }

  # Assume role for production access (optional)
  # assume_role {
  #   role_arn = "arn:aws:iam::${var.account_id}:role/TerraformExecutionRole"
  # }
}


provider "http" {}

# Data source for current AWS account
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
