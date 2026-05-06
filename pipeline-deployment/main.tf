module "cicd_pipeline" {
  source = "../modules/module-aws-tf-cicd"

  aws_region              = var.aws_region
  environment             = var.environment
  project_name            = var.project_name
  codestar_connection_arn = var.codestar_connection_arn
  github_repo_module      = var.github_repo_module
  github_repo_workload    = var.github_repo_workload
  github_branch           = var.github_branch
  artifacts_bucket_name   = var.artifacts_bucket_name
  state_bucket_name       = var.state_bucket_name
  dynamodb_table_name     = var.dynamodb_table_name
}



