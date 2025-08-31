# Create backend configuration for global resources

terraform {
  backend "s3" {
    bucket         = "terraform-state-106369262271-management-global"
    key            = "production/global/management-vpc/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-locks-global"
    encrypt        = true

    # Enterprise settings
    skip_region_validation      = false
    skip_credentials_validation = false
    skip_metadata_api_check     = false
  }
}

