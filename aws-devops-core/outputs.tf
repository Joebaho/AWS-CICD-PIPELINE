
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