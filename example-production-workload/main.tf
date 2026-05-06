terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "baho-backup-bucket"
    key            = "Codepipeline-backup/example-prod-workload/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "full-devops-table"
    encrypt        = true
  }
}

provider "aws" {
  region = "us-west-2"
}

# ── Call the reusable CICD module ──────────────────────────────

module "cicd_pipeline" {
  source = "../modules/module-aws-tf-cicd"

  aws_region   = "us-west-2"
  environment  = "production"
  project_name = "example-prod-workload"

  # Replace with your actual CodeStar Connection ARN after creating it in AWS console
  codestar_connection_arn = var.codestar_connection_arn

  github_repo_module   = "Joebaho/module-aws-tf-cicd"
  github_repo_workload = "Joebaho/example-prod-workload"
  github_branch        = "main"

  artifacts_bucket_name = "baho-prod-artifacts"
  state_bucket_name     = "baho-prod-tf-state"
  dynamodb_table_name   = "baho-prod-state-lock"
}

variable "codestar_connection_arn" {
  description = "CodeStar Connection ARN for GitHub integration"
  type        = string
}

output "deployment_pipeline_name" {
  value = module.cicd_pipeline.deployment_pipeline_name
}

output "state_bucket" {
  value = module.cicd_pipeline.state_bucket_name
}
