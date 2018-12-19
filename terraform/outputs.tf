output "vpc_id" {
  value       = "${module.vpc.vpc_id}"
  description = "VPC ID"
}

output "subnet_id" {
  value       = "${module.vpc.subnet_id}"
  description = "Subnet ID"
}

output "artifact_repo" {
  value       = "${module.pipeline.artifact_repo}"
  description = "S3 Bucket for Pipeline and Build Artifacts"
}

output "codebuild_service_role" {
  value       = "${module.pipeline.codebuild_service_role}"
  description = "CodeBuild IAM Service Role"
}

output "codepipeline_service_role" {
  value       = "${module.pipeline.codepipeline_service_role}"
  description = "CodePipeline IAM Service Role"
}

output "badge_url" {
  value       = "${module.pipeline.badge_url}"
  description = "The URL of the build badge"
}
