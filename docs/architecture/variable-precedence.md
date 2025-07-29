
# Terraform Variable Precedence (Lowest to Highest)

Default values in variables.tf
↓
Environment variables (TF_VAR_name)
↓
terraform.tfvars file
↓
terraform.tfvars.json file
↓
*.auto.tfvars files (alphabetical order)
↓
*.auto.tfvars.json files (alphabetical order)
↓
-var and -var-file options (CLI)

## Production Usage Pattern

1. **Base Configuration**: terraform.tfvars (version controlled)
2. **Dynamic Config**: terraform.tfvars.json (generated from CMDB)
3. **Compliance Overrides**: compliance-overrides.auto.tfvars.json
4. **Cost Optimization**: cost-optimization.auto.tfvars
5. **Secrets**: Environment variables (from Vault)
6. **Emergency**: CLI -var flags

## Example Loading in Production

```bash
# Files loaded in this order:
terraform.tfvars                         # Base config
terraform.tfvars.json                    # Generated from service catalog
compliance-overrides.auto.tfvars.json    # Compliance requirements
cost-optimization.auto.tfvars            # FinOps rules

# Plus environment variables:
TF_VAR_key_pair_name                     # From Vault
TF_VAR_allowed_ssh_cidrs                 # From Vault

# Emergency override:
terraform apply -var="instance_types={nat=\"t3.large\"...}"


