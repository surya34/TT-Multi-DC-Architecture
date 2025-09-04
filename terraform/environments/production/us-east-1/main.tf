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

  name_prefix           = local.name_prefix
  vpc_cidr              = var.vpc_cidr
  availability_zones    = var.availability_zones
  public_subnet_cidrs   = var.public_subnet_cidrs
  private_subnet_cidrs  = var.private_subnet_cidrs
  database_subnet_cidrs = var.database_subnet_cidrs



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

module "dynamodb-table" {
  source        = "../../../modules/data/dynamodb-table"
  name          = "s3-remediator-idemp"
  ttl_attribute = "ttl"
  tags = {
    Project = "serverless-guardrails"
    Env     = "prod"
  }
}

module "sqs_fifo" {
  source                  = "../../../modules/data/sqs-fifo"
  name                    = "s3-remediator-main"
  visibility_timeout_secs = 180  # if Lambda timeout is 30s (6x rule)
  kms_key_arn             = null # or your CMK ARN from modules/security
  eventbridge_rule_arns   = []   # or pass specific rule ARNs
  tags = {
    Project = "serverless-guardrails"
    Env     = "prod"
  }
}

# Pull the role ARN/name from the global state
data "terraform_remote_state" "prod_global" {
  backend = "s3"
  config = {
    bucket = "terraform-state-106369262271-management-global"
    key    = "production/global/management-vpc/terraform.tfstate"
    region = "us-east-1"
  }
}

# Example: fine-grained access for this region's resources
data "aws_iam_policy_document" "lambda_regional" {
  statement {
    sid       = "SQSReceive"
    actions   = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes", "sqs:ChangeMessageVisibility"]
    resources = [module.sqs_fifo.queue_arn] # from your SQS module in this stack
  }

  statement {
    sid       = "DDBIdempotency"
    actions   = ["dynamodb:PutItem", "dynamodb:GetItem"]
    resources = [module.dynamodb-table.table_arn] # from your DDB module in this stack
  }

  statement {
    sid       = "S3Remediate"
    actions   = ["s3:GetObjectAcl", "s3:PutObjectAcl", "s3:GetObjectTagging", "s3:PutObjectTagging"]
    resources = ["arn:aws:s3:::*/*"] # scope to bucket(s)
  }
}

resource "aws_iam_policy" "lambda_regional" {
  name   = "s3-remediator-exec-regional"
  policy = data.aws_iam_policy_document.lambda_regional.json
}

resource "aws_iam_role_policy_attachment" "lambda_regional_attach" {
  role       = data.terraform_remote_state.prod_global.outputs.lambda_exec_role_name
  policy_arn = aws_iam_policy.lambda_regional.arn
}

# Now create Lambda using the global role
resource "aws_lambda_function" "remediator" {
  function_name = "s3-public-acl-remediator"
  role          = data.terraform_remote_state.prod_global.outputs.lambda_exec_role_arn
  filename      = "build/build.zip"
  handler       = "handler.handler"
  runtime       = "python3.12"
  timeout       = 30
  memory_size   = 512
  tracing_config {
    mode = "Active"
  }
  environment {
    variables = {
      IDEMP_TABLE             = module.dynamodb-table.table_name
      POWERTOOLS_LOG_LEVEL    = "INFO"
      POWERTOOLS_SERVICE_NAME = "s3-remediator"
    }
  }
  reserved_concurrent_executions = 0 # cap to protect downstreams
}

# module for cloud watch

module "cloud_watch_rule" {
  source      = "../../../modules/cloud_watch/cloud_watch_rule"
  name        = "s3-acl-events"
  description = "Detect object-level ACL changes"
}

# setting sqs as target for the above eventbus/cloudwatch rule

resource "aws_cloudwatch_event_target" "to_sqs" {
 rule = module.cloud_watch_rule.rule_name
 arn = module.sqs_fifo.queue_arn
 sqs_target {
    message_group_id = "s3-remediator-events" 
  }
  input_transformer {
    input_paths = {
     bucket = "$.detail.bucket.name",
     key = "$.detail.object.key",
     versionId = "$.detail.object.version-id"
 }
 input_template = <<EOF
 {
 "bucket":"<bucket>",
 "key":"<key>",
 "versionId":"<versionId>"
 }
 EOF
}
# EventBridge retry + DLQ (optional on the rule itself)
dead_letter_config { 
 arn = module.sqs_fifo.queue_event_bridge_arn_dlq
}
retry_policy { 
maximum_retry_attempts = 6
maximum_event_age_in_seconds = 3600 
 }
}

# SQS → Lambda mapping , modularize later 

resource "aws_lambda_event_source_mapping" "sqs_es" {
event_source_arn = module.sqs_fifo.queue_arn
function_name = aws_lambda_function.remediator.function_name

}


