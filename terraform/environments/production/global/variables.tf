/**
 * Variables - Management VPC Production US-East-1
 * 
 * Production best practice: No hardcoded defaults for environment-specific values
 * Defaults only for truly universal constants
 */

# Core Configuration - No defaults (environment-specific)
variable "aws_region" {
  description = "AWS region for deployment"
  type        = string

  # No default - must be explicitly set per environment
}

variable "environment" {
  description = "Environment name (production/staging/development)"
  type        = string
  # No default - prevents accidental deployment to wrong environment

  validation {
    condition     = contains(["production", "staging", "development"], var.environment)
    error_message = "Environment must be production, staging, or development."
  }
}

