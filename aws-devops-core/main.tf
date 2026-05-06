data "aws_s3_bucket" "remote_state" {
  bucket = var.state_bucket_name
}

data "aws_dynamodb_table" "state_lock" {
  name = var.dynamodb_table_name
}

