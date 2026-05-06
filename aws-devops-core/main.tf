terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  description = "AWS region where the existing backend resources live"
  type        = string
  default     = "us-west-2"
}

variable "state_bucket_name" {
  description = "Existing S3 bucket used for Terraform remote state"
  type        = string
  default     = "baho-backup-bucket"
}

variable "state_key_prefix" {
  description = "S3 key prefix used for this project's Terraform state files"
  type        = string
  default     = "Codepipeline-backup"
}

variable "dynamodb_table_name" {
  description = "Existing DynamoDB table used for Terraform state locking"
  type        = string
  default     = "full-devops-table"
}

data "aws_s3_bucket" "remote_state" {
  bucket = var.state_bucket_name
}

data "aws_dynamodb_table" "state_lock" {
  name = var.dynamodb_table_name
}

output "state_bucket_name" {
  value = data.aws_s3_bucket.remote_state.bucket
}

output "state_key_prefix" {
  value = var.state_key_prefix
}

output "dynamodb_table_name" {
  value = data.aws_dynamodb_table.state_lock.name
}

output "aws_region" {
  value = var.aws_region
}
