variable "name" {
  type        = "string"
  description = "The name of the build environment"
  default     = "packer"
}

variable "region" {
  type        = "string"
  description = "The AWS region in which to build"
  default     = "us-east-1"
}

variable "vpc_cidr_prefix" {
  type        = "string"
  description = "The IP prefix to the CIDR block assigned to the VPC"
  default     = "10.72"
}
