module "IAM_lambda" {
  source    = "../../../modules/security/IAM_lambda"
  role_name = "s3-remediator-exec"
  # permissions_boundary_arn = module.permissions_boundary.arn # if you use one
  tags = {
    Env     = "prod"
    Project = "serverless-guardrails"
  }
}

output "lambda_exec_role_name" {
  value = module.IAM_lambda.role_name
}

output "lambda_exec_role_arn" {
  value = module.IAM_lambda.role_arn
}

