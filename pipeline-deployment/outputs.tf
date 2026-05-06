
output "module_validation_pipeline_name" {
  value = module.cicd_pipeline.module_validation_pipeline_name
}

output "deployment_pipeline_name" {
  value = module.cicd_pipeline.deployment_pipeline_name
}

output "artifacts_bucket_name" {
  value = module.cicd_pipeline.artifacts_bucket_name
}

output "state_bucket_name" {
  value = module.cicd_pipeline.state_bucket_name
}

output "kms_key_arn" {
  value = module.cicd_pipeline.kms_key_arn
}