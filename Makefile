PREFIX?=$(shell pwd)

NAME := unops
MANIFEST := $(CURDIR)/template.json

PACKER := packer
ANSIBLE_LINT := ansible-lint
ANSIBLE_PLAYBOOK := ansible-playbook

AWS_REGION := ${AWS_REGION}
VPC_ID := ${VPC_ID}
SUBNET_ID := ${SUBNET_ID}

IP := $(shell dig +short myip.opendns.com @resolver1.opendns.com)
AMI_USERS := $(shell aws organizations list-accounts | jq -r '[.Accounts[].Id | tonumber] | @csv')

PACKER_FLAGS = -var "temp_cidr=$(IP)/32" \
				-var "vpc_id=$(VPC_ID)" \
				-var "subnet_id=$(SUBNET_ID)" \
				-var "ami_users=$(AMI_USERS)" \
				-color=false

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
		@:$(call check_defined, SUBNET_ID, Subnet in which to run the source instance)
		$(PACKER) build \
			$(PACKER_FLAGS) \
			$(MANIFEST)

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
