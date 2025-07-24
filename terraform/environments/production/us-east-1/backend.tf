# Read backend configuration

BUCKET_NAME=$(cat .terraform-backend-bucket)
TABLE_NAME=$(cat .terraform-backend-table)

# Create backend configuration

terraform {
  backend "s3" {
    bucket         = "${BUCKET_NAME}"
    key            = "production/us-east-1/management-vpc/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "${TABLE_NAME}"
    encrypt        = true
    
    # Enterprise settings
    skip_region_validation      = false
    skip_credentials_validation = false
    skip_metadata_api_check     = false
  }
}

