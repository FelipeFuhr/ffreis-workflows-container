.DEFAULT_GOAL := help

##@ General

.PHONY: help
help: ## Show this help message
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Validation

.PHONY: lint
lint: ## Lint Containerfile in examples/hello with hadolint
	@command -v hadolint > /dev/null 2>&1 || { \
		echo "hadolint not found. Install it from https://github.com/hadolint/hadolint#install"; \
		exit 1; \
	}
	hadolint examples/hello/Containerfile

##@ Hooks

.PHONY: secrets-scan-staged
secrets-scan-staged: ## Scan staged files for secrets (fails if gitleaks not installed)
	@command -v gitleaks >/dev/null 2>&1 || { \
		echo "ERROR: gitleaks not found. Install it from https://github.com/gitleaks/gitleaks#installing"; \
		echo "Tip: run 'make setup' after installing to verify your dev environment."; \
		exit 1; \
	}
	gitleaks protect --staged --redact

.PHONY: lefthook-bootstrap
lefthook-bootstrap: ## Download lefthook binary to .bin/
	LEFTHOOK_VERSION="1.7.10" BIN_DIR=".bin" bash ./scripts/bootstrap_lefthook.sh

.PHONY: lefthook-install
lefthook-install: lefthook-bootstrap ## Install git hooks via lefthook
	./.bin/lefthook install

.PHONY: hooks
hooks: lefthook-install ## Bootstrap and install all git hooks

.PHONY: setup
setup: hooks ## Install git hooks and verify required tools
	@command -v gitleaks >/dev/null 2>&1 || { \
		echo ""; \
		echo "ACTION REQUIRED: gitleaks is not installed."; \
		echo "Install it from https://github.com/gitleaks/gitleaks#installing then re-run 'make setup'."; \
		echo ""; \
		exit 1; \
	}
	@echo "Dev environment ready."
