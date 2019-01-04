variable "bucket_name" {
  type        = "string"
  description = "the name of the build artifacts bucket"
}

variable "service_name" {
  type        = "string"
  description = "the name of the service; used in the code repository and pipeline names"
}

variable "region" {
  type        = "string"
  description = "the AWS region in which the AMI will be built"
}

variable "image" {
  type        = "string"
  description = "Docker image to use for the codebuild container"
  default     = "python:3.7.1"
}

variable "vpc_id" {
  type        = "string"
  description = "the id of the VPC in which the AMI will be built"
}

variable "subnet_id" {
  type        = "string"
  description = "the id of the subnet in which the AMI will be built"
}

variable "repo_owner" {
  type        = "string"
  description = "github organization or user who owns the repository"
}

variable "repo" {
  type        = "string"
  description = "the name of the Github repository to build"
}

variable "branch" {
  type        = "string"
  description = "the name of the Github repository's branch to build"
  default     = "master"
}

variable "github_token" {
  type        = "string"
  description = "github personal access token"
}
