# ── Pipeline 1: Terraform Module Validation Pipeline ──────────
# Stages: Source → Build_TF_Test → Build_Checkov → Build_TFLint

resource "aws_codepipeline" "module_validation" {
  name     = "${var.project_name}-module-validation"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_artifacts.bucket
    type     = "S3"
    encryption_key {
      id   = aws_kms_key.cicd.arn
      type = "KMS"
    }
  }

  stage {
    name = "Source"
    action {
      name             = "PullFromGitHub"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output_artifacts"]
      run_order        = 1

      configuration = {
        ConnectionArn    = var.codestar_connection_arn
        FullRepositoryId = var.github_repo_module
        BranchName       = var.github_branch
        DetectChanges    = "true"
      }
    }
  }

  stage {
    name = "Build_TF_Test"
    action {
      name             = "TerraformTest"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output_artifacts"]
      output_artifacts = ["tf_test_output"]
      run_order        = 1

      configuration = {
        ProjectName = aws_codebuild_project.tf_test.name
      }
    }
  }

  stage {
    name = "Build_Checkov"
    action {
      name             = "Checkov"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output_artifacts"]
      output_artifacts = ["checkov_output"]
      run_order        = 1

      configuration = {
        ProjectName = aws_codebuild_project.checkov.name
      }
    }
  }

  stage {
    name = "Build_TFLint"
    action {
      name             = "TFLint"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output_artifacts"]
      output_artifacts = ["tflint_output"]
      run_order        = 1

      configuration = {
        ProjectName = aws_codebuild_project.tflint.name
      }
    }
  }
}

# ── Pipeline 2: Terraform Deployment Pipeline ─────────────────
# Stages: Source → Build_TF_Test → Build_Checkov → Build_TFLint → Apply

resource "aws_codepipeline" "deployment" {
  name     = "${var.project_name}-deployment"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_artifacts.bucket
    type     = "S3"
    encryption_key {
      id   = aws_kms_key.cicd.arn
      type = "KMS"
    }
  }

  stage {
    name = "Source"
    action {
      name             = "PullFromGitHub"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output_artifacts"]
      run_order        = 1

      configuration = {
        ConnectionArn    = var.codestar_connection_arn
        FullRepositoryId = var.github_repo_workload
        BranchName       = var.github_branch
        DetectChanges    = "true"
      }
    }
  }

  stage {
    name = "Build_TF_Test"
    action {
      name             = "TerraformTest"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output_artifacts"]
      output_artifacts = ["tf_test_output"]
      run_order        = 1

      configuration = {
        ProjectName = aws_codebuild_project.tf_test.name
      }
    }
  }

  stage {
    name = "Build_Checkov"
    action {
      name             = "Checkov"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output_artifacts"]
      output_artifacts = ["checkov_output"]
      run_order        = 1

      configuration = {
        ProjectName = aws_codebuild_project.checkov.name
      }
    }
  }

  stage {
    name = "Build_TFLint"
    action {
      name             = "TFLint"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output_artifacts"]
      output_artifacts = ["tflint_output"]
      run_order        = 1

      configuration = {
        ProjectName = aws_codebuild_project.tflint.name
      }
    }
  }

  stage {
    name = "Apply"
    action {
      name             = "TerraformApply"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output_artifacts"]
      output_artifacts = ["apply_output"]
      run_order        = 1

      configuration = {
        ProjectName = aws_codebuild_project.tf_apply.name
      }
    }
  }
}
