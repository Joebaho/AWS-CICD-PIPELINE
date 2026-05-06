

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