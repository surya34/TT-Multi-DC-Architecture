# scripts/deployment/set-env-vars.sh
#!/bin/bash

# Used for sensitive values that shouldn't be in files
# Perfect for CI/CD pipelines

#!/bin/bash
# Environment Variables for Sensitive Configuration
# Used in CI/CD pipelines to avoid storing secrets in code

# Security-sensitive variables (from AWS Secrets Manager in real pipeline)
export TF_VAR_key_pair_name="mgmt-vpc-prod-key"
export TF_VAR_allowed_ssh_cidrs='["0.0.0.0/0"]'  # Would be restricted in real prod

# Account-specific (from pipeline context)
export TF_VAR_aws_account_id=$(aws sts get-caller-identity --query Account --output text)

# Dynamic values that change per deployment
export TF_VAR_cost_center="${COST_CENTER:-platform-engineering}"

echo "✅ Environment variables set for Terraform"
echo "Account ID: ${TF_VAR_aws_account_id}"

