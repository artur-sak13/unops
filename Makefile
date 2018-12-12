PREFIX?=$(shell pwd)

NAME := unops
MANIFEST := $(CURDIR)/template.json

PACKER := packer
ANSIBLE_LINT := ansible-lint

VPC_ID := ${VPC_ID}
IAM_PROF := ${IAM_PROF}
SUBNET_ID := ${SUBNET_ID}

IP := $(shell dig +short myip.opendns.com @resolver1.opendns.com)

PACKER_FLAGS := -var "temp_cidr=$(IP)/32" \
				-var "vpc_id=$(VPC_ID)" \
				-var "subnet_id=$(SUBNET_ID)" \
				-var "iam_prof=$(IAM_PROF)" \
				-var "access_key=$(AWS_ACCESS_KEY_ID)" \
				-var "secret_key=$(AWS_SECRET_ACCESS_KEY)"

all: test ami ## Runs test, ami
.PHONY: ami
ami: ## Builds the AMI
		PACKER_LOG=1 $(PACKER) build \
			$(PACKER_FLAGS) \
			$(MANIFEST)

.PHONY: test
test: ## Runs the automated tests
	@echo "+ $@"
	$(PACKER) validate --syntax-only $(MANIFEST)
	$(ANSIBLE_LINT) ${PREFIX}/ansible/playbook.yml -x ANSIBLE0010
	$(CURDIR)/test.sh

.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
