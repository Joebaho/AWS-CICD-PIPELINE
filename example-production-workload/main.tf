module "cicd_pipeline" {
  source = "../modules/module-aws-tf-cicd"

  aws_region   = "us-west-2"
  environment  = "production"
  project_name = "aws-cicd-pipeline-prod"

  # Replace with your actual CodeStar Connection ARN after creating it in AWS console
  codestar_connection_arn = var.codestar_connection_arn

  github_repo_module   = "Joebaho/AWS-CICD-PIPELINE"
  github_repo_workload = "Joebaho/AWS-CICD-PIPELINE"
  github_branch        = "main"

  artifacts_bucket_name = "baho-prod-artifacts"
  state_bucket_name     = "baho-prod-tf-state"
  dynamodb_table_name   = "baho-prod-state-lock"
}

