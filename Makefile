SHELL := /bin/bash

.PHONY: help fmt lint docs test validate-all

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

fmt: ## Format all Terraform files
	terraform fmt -recursive

lint: ## Run tflint and checkov
	@for dir in modules/*/; do \
		echo "==> Linting $$dir"; \
		(cd "$$dir" && tflint --init --config ../../.tflint.hcl && tflint --config ../../.tflint.hcl && checkov -d . --framework terraform 2>/dev/null || true); \
	done

docs: ## Generate terraform-docs for all modules
	@for dir in modules/*/; do \
		echo "==> Docs for $$dir"; \
		terraform-docs -c terraform-docs.yml "$$dir"; \
	done

validate-all: ## Validate all modules
	@for dir in modules/*/; do \
		echo "==> Validating $$dir"; \
		(cd "$$dir" && terraform init -backend=false && terraform validate); \
	done

test: ## Run Terratest tests
	cd tests && go test -v ./...
