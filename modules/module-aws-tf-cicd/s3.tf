# ── CodePipeline Artifacts Bucket ─────────────────────────────

resource "aws_s3_bucket" "codepipeline_artifacts" {
  #checkov:skip=CKV_AWS_18:Access logging is intentionally omitted for this lab pipeline bucket.
  #checkov:skip=CKV_AWS_144:Cross-region replication is not required for this single-region project.
  #checkov:skip=CKV2_AWS_62:Bucket notifications are not required for CodePipeline artifact storage.
  bucket        = "${var.artifacts_bucket_name}-${random_id.suffix.hex}"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "codepipeline_artifacts" {
  bucket = aws_s3_bucket.codepipeline_artifacts.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "codepipeline_artifacts" {
  bucket = aws_s3_bucket.codepipeline_artifacts.id
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.cicd.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "codepipeline_artifacts" {
  bucket                  = aws_s3_bucket.codepipeline_artifacts.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "codepipeline_artifacts" {
  bucket = aws_s3_bucket.codepipeline_artifacts.id
  rule {
    id     = "cleanup-incomplete-uploads"
    status = "Enabled"
    filter {
      prefix = ""
    }
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# ── Terraform Remote State Bucket ─────────────────────────────

resource "aws_s3_bucket" "tf_remote_state_s3_buckets" {
  #checkov:skip=CKV_AWS_18:Access logging is intentionally omitted for this lab state bucket.
  #checkov:skip=CKV_AWS_144:Cross-region replication is not required for this single-region project.
  #checkov:skip=CKV2_AWS_62:Bucket notifications are not required for Terraform state storage.
  bucket        = "${var.state_bucket_name}-${random_id.suffix.hex}"
  force_destroy = false
}

resource "aws_s3_bucket_versioning" "tf_state" {
  bucket = aws_s3_bucket.tf_remote_state_s3_buckets.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state" {
  bucket = aws_s3_bucket.tf_remote_state_s3_buckets.id
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.cicd.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "tf_remote_state_s3_buckets" {
  bucket                  = aws_s3_bucket.tf_remote_state_s3_buckets.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "tf_state" {
  bucket = aws_s3_bucket.tf_remote_state_s3_buckets.id
  rule {
    id     = "expire-old-versions"
    status = "Enabled"
    filter {
      prefix = ""
    }
    noncurrent_version_expiration {
      noncurrent_days = 90
    }
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# ── DynamoDB State Lock Table ──────────────────────────────────

resource "aws_dynamodb_table" "tf_state_lock" {
  name         = var.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.cicd.arn
  }

  point_in_time_recovery {
    enabled = true
  }
}

# ── Random suffix for globally unique bucket names ─────────────

resource "random_id" "suffix" {
  byte_length = 4
}
