variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
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
  description = "GitHub repo ID for the Terraform module (owner/repo)"
  type        = string
  default     = "Joebaho/AWS-CICD-PIPELINE"
}

variable "github_repo_workload" {
  description = "GitHub repo ID for the example production workload (owner/repo)"
  type        = string
  default     = "Joebaho/AWS-CICD-PIPELINE"
}

variable "github_branch" {
  description = "GitHub branch to trigger pipeline"
  type        = string
  default     = "main"
}

variable "tf_version" {
  description = "Terraform version to use in CodeBuild"
  type        = string
  default     = "1.11.3"
}

variable "checkov_version" {
  description = "Checkov version for security scanning"
  type        = string
  default     = "3.2.403"
}

variable "artifacts_bucket_name" {
  description = "Name for CodePipeline artifacts S3 bucket"
  type        = string
  default     = "baho-codepipeline-artifacts"
}

variable "state_bucket_name" {
  description = "Name for Terraform remote state S3 bucket"
  type        = string
  default     = "baho-pipeline-tf-state"
}

variable "dynamodb_table_name" {
  description = "DynamoDB table name for state locking"
  type        = string
  default     = "baho-pipeline-state-lock"
}
