# tests/main.tftest.hcl
# Native Terraform Test Framework
# Run with: terraform test

# ── Input Validation (Unit Test) ──────────────────────────────

run "input_validation" {
  command = plan

  variables {
    aws_region              = "us-west-2"
    environment             = "test"
    project_name            = "test-cicd"
    codestar_connection_arn = "arn:aws:codestar-connections:us-west-2:123456789:connection/test"
    github_repo_module      = "Joebaho/module-aws-tf-cicd"
    github_repo_workload    = "Joebaho/example-prod-workload"
    github_branch           = "main"
    artifacts_bucket_name   = "test-codepipeline-artifacts"
    state_bucket_name       = "test-tf-state"
    dynamodb_table_name     = "test-state-lock"
  }

  # Validate S3 artifacts bucket will be created
  assert {
    condition     = aws_s3_bucket.codepipeline_artifacts.force_destroy == true
    error_message = "Artifacts bucket must allow force_destroy in non-prod environments"
  }

  # Validate DynamoDB table has correct hash key
  assert {
    condition     = aws_dynamodb_table.tf_state_lock.hash_key == "LockID"
    error_message = "DynamoDB table must use LockID as hash key for Terraform state locking"
  }

  # Validate public access is blocked on state bucket
  assert {
    condition     = aws_s3_bucket_public_access_block.tf_remote_state_s3_buckets.block_public_acls == true
    error_message = "State bucket must block all public access"
  }

  # Validate CodeBuild roles are created
  assert {
    condition     = aws_iam_role.codebuild_role.name == "test-cicd-codebuild-role"
    error_message = "CodeBuild IAM role name does not match expected pattern"
  }
}

# ── Pipeline Structure Test ───────────────────────────────────

run "pipeline_structure" {
  command = plan

  variables {
    aws_region              = "us-west-2"
    environment             = "test"
    project_name            = "pipeline-structure-test"
    codestar_connection_arn = "arn:aws:codestar-connections:us-west-2:123456789:connection/test"
    github_repo_module      = "Joebaho/module-aws-tf-cicd"
    github_repo_workload    = "Joebaho/example-prod-workload"
    github_branch           = "main"
    artifacts_bucket_name   = "pipeline-structure-artifacts"
    state_bucket_name       = "pipeline-structure-tf-state"
    dynamodb_table_name     = "pipeline-structure-state-lock"
  }

  # Validate both pipelines were created
  assert {
    condition     = aws_codepipeline.module_validation.name != ""
    error_message = "Module validation pipeline was not created"
  }

  assert {
    condition     = aws_codepipeline.deployment.name != ""
    error_message = "Deployment pipeline was not created"
  }

  # Validate all CodeBuild projects exist
  assert {
    condition     = aws_codebuild_project.tf_test.name != ""
    error_message = "TF Test CodeBuild project was not created"
  }

  assert {
    condition     = aws_codebuild_project.checkov.name != ""
    error_message = "Checkov CodeBuild project was not created"
  }

  assert {
    condition     = aws_codebuild_project.tflint.name != ""
    error_message = "TFLint CodeBuild project was not created"
  }

  assert {
    condition     = aws_codebuild_project.tf_apply.name != ""
    error_message = "TF Apply CodeBuild project was not created"
  }
}
