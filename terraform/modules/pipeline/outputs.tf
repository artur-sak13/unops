output "artifact_repo" {
  value       = "${aws_s3_bucket.unops.bucket}"
  description = "S3 Bucket for Pipeline and Build Artifacts"
}

output "codebuild_service_role" {
  value       = "${aws_iam_role.codebuild_role.arn}"
  description = "CodeBuild IAM Service Role"
}

output "codepipeline_service_role" {
  value       = "${aws_iam_role.codepipeline_role.arn}"
  description = "CodePipeline IAM Service Role"
}

output "badge_url" {
  value       = "${aws_codebuild_project.badge_url}"
  description = "The URL of the build badge"
}
