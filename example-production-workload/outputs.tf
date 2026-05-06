
output "deployment_pipeline_name" {
  value = module.cicd_pipeline.deployment_pipeline_name
}

output "state_bucket" {
  value = module.cicd_pipeline.state_bucket_name
}