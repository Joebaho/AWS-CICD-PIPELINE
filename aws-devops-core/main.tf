data "aws_s3_bucket" "remote_state" {
  bucket = var.state_bucket_name
}
