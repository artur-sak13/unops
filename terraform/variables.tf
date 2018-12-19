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

variable "account_id" {
  type        = "string"
  description = "the AWS account id (not IAM Account) in which the AMI will be built"
}

variable "image" {
  type        = "string"
  description = "Docker image to use for the codebuild container"
  default     = "eb-python-2.7-amazonlinux-64:2.1.6"
}

variable "organization" {
  type        = "string"
  description = "the user or organization who owns the repo"
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