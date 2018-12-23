variable "access_key" {
  type    = "string"
  default = "YOUR_ADMIN_ACCESS_KEY"
}

variable "secret_key" {
  type    = "string"
  default = "YOUR_ADMIN_SECRET_KEY"
}

variable "bucket_name" {
  type        = "string"
  description = "the name of the build artifacts bucket"
}

variable "name" {
  type        = "string"
  description = "the name of the build environment"
  default     = "packer"
}

variable "vpc_cidr_prefix" {
  type        = "string"
  description = "the IP prefix to the CIDR block assigned to the VPC"
  default     = "10.72"
}

variable "service_name" {
  type        = "string"
  description = "the name of the service; used in the code repository and pipeline names"
}

variable "region" {
  type        = "string"
  description = "the AWS region in which the AMI will be built"
  default     = "us-east-1"
}

variable "image" {
  type        = "string"
  description = "Docker image to use for the codebuild container"
  default     = "eb-python-2.7-amazonlinux-64:2.1.6"
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

variable "sms_number" {
  type        = "string"
  description = "sms number to notify on completed build"
}
