output "artifacts_bucket_name" {
  description = "Name of the CodePipeline artifacts S3 bucket"
  value       = aws_s3_bucket.codepipeline_artifacts.bucket
}

output "state_bucket_name" {
  description = "Name of the Terraform remote state S3 bucket"
  value       = aws_s3_bucket.tf_remote_state_s3_buckets.bucket
}

output "dynamodb_table_name" {
  description = "DynamoDB table name for state locking"
  value       = aws_dynamodb_table.tf_state_lock.name
}

output "kms_key_arn" {
  description = "KMS key ARN used by CI/CD resources"
  value       = aws_kms_key.cicd.arn
}

output "module_validation_pipeline_name" {
  description = "Name of the module validation CodePipeline"
  value       = aws_codepipeline.module_validation.name
}

output "deployment_pipeline_name" {
  description = "Name of the deployment CodePipeline"
  value       = aws_codepipeline.deployment.name
}

output "codebuild_tf_test_name" {
  description = "CodeBuild project name for Terraform tests"
  value       = aws_codebuild_project.tf_test.name
}

output "codebuild_checkov_name" {
  description = "CodeBuild project name for Checkov scans"
  value       = aws_codebuild_project.checkov.name
}

output "codebuild_tflint_name" {
  description = "CodeBuild project name for TFLint checks"
  value       = aws_codebuild_project.tflint.name
}

output "codebuild_tf_apply_name" {
  description = "CodeBuild project name for Terraform apply"
  value       = aws_codebuild_project.tf_apply.name
}

output "account_id" {
  description = "AWS Account ID"
  value       = local.account_id
}
