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
  default     = "aws-cicd-pipeline"
}

variable "codestar_connection_arn" {
  description = "CodeStar Connection ARN for GitHub integration"
  type        = string
}

variable "github_repo_module" {
  description = "GitHub repo ID for the Terraform module, formatted as owner/repo"
  type        = string
  default     = "Joebaho/AWS-CICD-PIPELINE"
}

variable "github_repo_workload" {
  description = "GitHub repo ID for the workload, formatted as owner/repo"
  type        = string
  default     = "Joebaho/AWS-CICD-PIPELINE"
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
