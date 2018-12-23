PREFIX?=$(shell pwd)

NAME := unops
MANIFEST := $(CURDIR)/template.json

PACKER := packer
ANSIBLE_LINT := ansible-lint
ANSIBLE_PLAYBOOK := ansible-playbook

ACCOUNT_ID := ${ACCOUNT_ID}
AWS_REGION := ${AWS_REGION}
AWS_ACCESS_KEY_ID := ${AWS_ACCESS_KEY_ID}
AWS_SECRET_ACCESS_KEY := ${AWS_SECRET_ACCESS_KEY}
BUCKET := ${BUCKET}
BUILD_BUCKET := ${BUILD_BUCKET}
VPC_ID := ${VPC_ID}
IAM_PROF := ${IAM_PROF}
SUBNET_ID := ${SUBNET_ID}
GITHUB_TOKEN := ${GITHUB_TOKEN}
SMS_NUMBER := ${SMS_NUMBER}

IP := $(shell dig +short myip.opendns.com @resolver1.opendns.com)

REPO_OWNER := $(shell git config --get user.name)
REPO := $(shell git rev-parse --show-toplevel | xargs basename)
BRANCH := $(shell git name-rev --name-only --no-undefined --always HEAD)

TERRAFORM_DIR = $(CURDIR)/terraform

PACKER_FLAGS = -var "temp_cidr=$(IP)/32" \
				-var "vpc_id=$(VPC_ID)" \
				-var "subnet_id=$(SUBNET_ID)" \
				-var "iam_prof=$(IAM_PROF)" \
				-color=false

TERRAFORM_FLAGS = -var "region=$(AWS_REGION)" \
				  -var "access_key=$(AWS_ACCESS_KEY_ID)" \
				  -var "secret_key=$(AWS_SECRET_ACCESS_KEY)" \
				  -var "subnet_id="$(SUBNET_ID) \
				  -var "bucket_name=$(BUILD_BUCKET)" \
				  -var "name=$(NAME)" \
				  -var "vpc_cidr_prefix=$(VPC_CIDR)" \
				  -var "service_name=$(NAME)" \
				  -var "repo_owner=$(REPO_OWNER)" \
				  -var "repo=$(REPO)" \
					-var "github_token=$(GITHUB_TOKEN)" \
					-var "sms_number=$(SMS_NUMBER)"

check_defined = \
		$(strip $(foreach 1,$1, \
		$(call __check_defined,$1,$(strip $(value 2)))))
__check_defined = \
		$(if $(value $1),, \
		$(error Undefined $1$(if $2, ($2))$(if $(value @), \
		required by target `$@')))

all: test ami ## Runs test, ami

.PHONY: ami
ami: ## Builds the AMI
		@:$(call check_defined, VPC_ID, Virtual Private Cloud to build in)
		@:$(call check_defined, IAM_PROF, IAM Profile to use with the source instance)
		@:$(call check_defined, SUBNET_ID, Subnet in which to run the source instance)
		$(PACKER) build \
			$(PACKER_FLAGS) \
			$(MANIFEST)

.PHONY: infra-init
infra-init:
		@:$(call check_defined, AWS_REGION, Amazon Region)
		@:$(call check_defined, AWS_ACCESS_KEY_ID, Amazon Access Key ID)
		@:$(call check_defined, AWS_SECRET_ACCESS_KEY, Amazon Secret Access Key)
		@:$(call check_defined, SUBNET_ID, Subnet in which to build the AMI)
		@:$(call check_defined, BUCKET, S3 bucket name in which to store the Terraform state)
		@:$(call check_defined, NAME, Name of the build environment)
		@:$(call check_defined, VPC_CIDR, The IP prefix to the CIDR block assigned to the VPC)
		@:$(call check_defined, REPO_OWNER, The Github organization or user who owns the repository)
		@:$(call check_defined, REPO, The Github repo containing the Packer templates used to build the AMI)
		@:$(call check_defined, GITHUB_TOKEN, Github OAuth Personal Access token)
		@:$(call check_defined, SMS_NUMBER, SMS number to notify on completed build)
		@cd $(TERRAFORM_DIR) && terraform init \
				-backend-config "bucket=$(BUCKET)" \
				-backend-config "region=$(AWS_REGION)" \
				$(TERRAFORM_FLAGS)

.PHONY: infra-plan
infra-plan: infra-init ## Run terraform plan
		@cd $(TERRAFORM_DIR) && terraform plan \
				$(TERRAFORM_FLAGS)

.PHONY: infra-apply
infra-apply: infra-init ## Run terraform apply
		@cd $(TERRAFORM_DIR) && terraform apply \
				$(TERRAFORM_FLAGS) \
				-auto-approve

.PHONY: infra-destroy
infra-destroy: infra-init ## Run terraform destroy
		@cd $(TERRAFORM_DIR) && terraform destroy \
				$(TERRAFORM_FLAGS)

.PHONY: test
test: ## Runs the automated tests
	@echo "+ $@"
	$(PACKER) validate --syntax-only $(MANIFEST)
	$(ANSIBLE_PLAYBOOK) --syntax-check ${PREFIX}/ansible/playbook.yml
	$(ANSIBLE_LINT) ${PREFIX}/ansible/playbook.yml -x ANSIBLE0010
	$(CURDIR)/test.sh

.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
