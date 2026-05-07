
output "state_bucket_name" {
  value = data.aws_s3_bucket.remote_state.bucket
}

output "state_key_prefix" {
  value = var.state_key_prefix
}

output "aws_region" {
  value = var.aws_region
}
