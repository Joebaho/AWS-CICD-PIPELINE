# ── CodeBuild: Terraform Test Framework ───────────────────────

resource "aws_codebuild_project" "tf_test" {
  name           = "${var.project_name}-tf-test"
  description    = "Runs Terraform Test Framework - unit, integration, e2e tests"
  build_timeout  = 30
  service_role   = aws_iam_role.codebuild_role.arn
  encryption_key = aws_kms_key.cicd.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "TF_VERSION"
      value = var.tf_version
    }
    environment_variable {
      name  = "TF_STATE_BUCKET"
      value = aws_s3_bucket.tf_remote_state_s3_buckets.bucket
    }
    environment_variable {
      name  = "TF_LOCK_TABLE"
      value = aws_dynamodb_table.tf_state_lock.name
    }
    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = var.aws_region
    }
    environment_variable {
      name  = "TF_VAR_codestar_connection_arn"
      value = var.codestar_connection_arn
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = file("${path.module}/buildspec/tf-test-buildspec.yml")
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "/codebuild/${var.project_name}-tf-test"
      stream_name = "build-log"
    }
  }
}

# ── CodeBuild: Checkov Security Scan ──────────────────────────

resource "aws_codebuild_project" "checkov" {
  name           = "${var.project_name}-checkov"
  description    = "Runs Checkov static security analysis on Terraform code"
  build_timeout  = 20
  service_role   = aws_iam_role.codebuild_role.arn
  encryption_key = aws_kms_key.cicd.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "CHECKOV_VERSION"
      value = var.checkov_version
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = file("${path.module}/buildspec/checkov-buildspec.yml")
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "/codebuild/${var.project_name}-checkov"
      stream_name = "build-log"
    }
  }
}

# ── CodeBuild: TFLint ─────────────────────────────────────────

resource "aws_codebuild_project" "tflint" {
  name           = "${var.project_name}-tflint"
  description    = "Runs TFLint static analysis on Terraform code"
  build_timeout  = 20
  service_role   = aws_iam_role.codebuild_role.arn
  encryption_key = aws_kms_key.cicd.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = file("${path.module}/buildspec/tflint-buildspec.yml")
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "/codebuild/${var.project_name}-tflint"
      stream_name = "build-log"
    }
  }
}

# ── CodeBuild: Terraform Apply ─────────────────────────────────

resource "aws_codebuild_project" "tf_apply" {
  name           = "${var.project_name}-tf-apply"
  description    = "Runs terraform apply to provision AWS resources"
  build_timeout  = 60
  service_role   = aws_iam_role.codebuild_role.arn
  encryption_key = aws_kms_key.cicd.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_MEDIUM"
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "TF_VERSION"
      value = var.tf_version
    }
    environment_variable {
      name  = "TF_STATE_BUCKET"
      value = aws_s3_bucket.tf_remote_state_s3_buckets.bucket
    }
    environment_variable {
      name  = "TF_LOCK_TABLE"
      value = aws_dynamodb_table.tf_state_lock.name
    }
    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = var.aws_region
    }
    environment_variable {
      name  = "TF_VAR_codestar_connection_arn"
      value = var.codestar_connection_arn
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = file("${path.module}/buildspec/tf-apply-buildspec.yml")
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "/codebuild/${var.project_name}-tf-apply"
      stream_name = "build-log"
    }
  }
}
