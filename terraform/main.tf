provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"

  region  = "${var.region}"
  version = "~> 1.47.0"
}

module "vpc" {
  source          = "./modules/vpc"
  name            = "${var.name}"
  region          = "${var.region}"
  vpc_cidr_prefix = "${var.vpc_cidr_prefix}"
}

module "pipeline" {
  source       = "./modules/pipeline"
  bucket_name  = "${var.bucket_name}"
  service_name = "${var.service_name}"
  region       = "${var.region}"
  image        = "${var.image}"
  vpc_id       = "${module.vpc.vpc_id}"
  subnet_id    = "${module.vpc.subnet_id}"
  repo_owner   = "${var.repo_owner}"
  repo         = "${var.repo}"
  branch       = "${var.branch}"
  github_token = "${var.github_token}"
  sms_number   = "${var.sms_number}"
}

terraform {
  required_version = ">= 0.11.11"

  backend "s3" {
    bucket  = "twopoint-tf-state"
    encrypt = true
    key     = "unops/terraform.tfstate"
  }
}
