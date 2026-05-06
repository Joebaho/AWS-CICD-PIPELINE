terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  backend "s3" {
    bucket         = "baho-backup-bucket"
    key            = "Codepipeline-backup/module-aws-tf-cicd/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "full-devops-table"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}

module "cicd_pipeline" {
  source = "../modules/module-aws-tf-cicd"

  aws_region              = var.aws_region
  environment             = var.environment
  project_name            = var.project_name
  codestar_connection_arn = var.codestar_connection_arn
  github_repo_module      = var.github_repo_module
  github_repo_workload    = var.github_repo_workload
  github_branch           = var.github_branch
  artifacts_bucket_name   = var.artifacts_bucket_name
  state_bucket_name       = var.state_bucket_name
  dynamodb_table_name     = var.dynamodb_table_name
}

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "module-aws-tf-cicd"
}

variable "codestar_connection_arn" {
  description = "CodeStar Connection ARN for GitHub integration"
  type        = string
}

variable "github_repo_module" {
  description = "GitHub repo ID for the Terraform module, formatted as owner/repo"
  type        = string
  default     = "Joebaho/module-aws-tf-cicd"
}

variable "github_repo_workload" {
  description = "GitHub repo ID for the workload, formatted as owner/repo"
  type        = string
  default     = "Joebaho/example-prod-workload"
}

variable "github_branch" {
  description = "GitHub branch to trigger the pipeline"
  type        = string
  default     = "main"
}

variable "artifacts_bucket_name" {
  description = "Base name for the CodePipeline artifacts S3 bucket"
  type        = string
  default     = "baho-codepipeline-artifacts"
}

variable "state_bucket_name" {
  description = "Base name for the Terraform remote state S3 bucket created by the pipeline module"
  type        = string
  default     = "baho-pipeline-tf-state"
}

variable "dynamodb_table_name" {
  description = "DynamoDB table name for Terraform state locking"
  type        = string
  default     = "baho-pipeline-state-lock"
}

output "module_validation_pipeline_name" {
  value = module.cicd_pipeline.module_validation_pipeline_name
}

output "deployment_pipeline_name" {
  value = module.cicd_pipeline.deployment_pipeline_name
}

output "artifacts_bucket_name" {
  value = module.cicd_pipeline.artifacts_bucket_name
}

output "state_bucket_name" {
  value = module.cicd_pipeline.state_bucket_name
}

output "kms_key_arn" {
  value = module.cicd_pipeline.kms_key_arn
}
