# Colors for output
GREEN = \033[0;32m
YELLOW = \033[1;33m
RED = \033[0;31m
CYAN = \033[0;36m
# No Color
NC = \033[0m

# Symbols
CHECK="✓"
CROSS="✗"
WARN="⚠"

.PHONY: help
help: ## Show this help message
	@echo "$(YELLOW)Available Commands:$(NC)"
	@awk ' \
		BEGIN {FS = ":.*?## "} \
		/^###/ {printf "\n$(YELLOW)%s$(NC)\n", substr($$0, 5); next} \
		/^[a-zA-Z_-]+:.*?## / {printf "  $(GREEN)%-30s$(NC) %s\n", $$1, $$2} \
	' $(MAKEFILE_LIST)
	@echo ""

# ------------------------------------------------------------------------------
### Local development commands:
# ------------------------------------------------------------------------------

.PHONY: check-requirements
check-requirements: ## Check all local development requirements and tool versions
	@./scripts/check-local-requirements.sh

.PHONY: start-local
start-local: ## Start the full local environment (postgres + redis + lgtm)
	@echo "$(CYAN)Starting local environment...$(NC)"
	@test -f local/.env || { cp local/.env.example local/.env && echo "$(YELLOW)Created local/.env from .env.example$(NC)"; }
	@docker compose -f local/docker-compose.yml up -d
	@echo "$(CYAN)Docker containers started:$(NC)"
	@docker ps | grep -E "ecommerce-postgres|ecommerce-redis|ecommerce-otel-lgtm"
	@echo "$(GREEN)$(CHECK) Local environment ready$(NC)"

# Reusable shell snippets. Make joins the lines into one shell line, so every
# command ends with ';'. Put $(AWS_READ_ENV) and $(AWS_READ_PROFILE) at the start
# of a recipe, in the same shell line as the terraform command (they set ENV and
# SSO_PROFILE). $$ is a single $ for the shell.
AWS_TF_DIR = aws/terraform/environments/$$ENV

AWS_READ_ENV = \
	echo -n "$(CYAN)Enter environment (dev, prod): $(NC)"; \
	read ENV; \
	if [ -z "$$ENV" ]; then \
		echo "$(RED)$(CROSS) Environment cannot be empty$(NC)"; exit 1; \
	fi; \
	case "$$ENV" in \
		dev|prod) ;; \
		*) echo "$(RED)$(CROSS) Environment must be dev or prod, got '$$ENV'$(NC)"; exit 1 ;; \
	esac;

AWS_READ_PROFILE = \
	echo -n "$(CYAN)Enter SSO profile (leave empty if not using SSO): $(NC)"; \
	read SSO_PROFILE;

.PHONY: aws-tf-init
aws-tf-init: ## Initialize an AWS terraform environment (dev, prod)
	@$(AWS_READ_ENV) \
	$(AWS_READ_PROFILE) \
	BACKEND_ARGS=""; \
	if [ -n "$$SSO_PROFILE" ]; then BACKEND_ARGS="-backend-config=profile=$$SSO_PROFILE"; fi; \
	echo "$(CYAN)Initializing $(GREEN)$$ENV$(NC)$(CYAN) with profile $(GREEN)$${SSO_PROFILE:-none}$(NC)"; \
	terraform -chdir=$(AWS_TF_DIR) init $$BACKEND_ARGS

.PHONY: aws-tf-plan
aws-tf-plan: ## Run terraform plan for an AWS environment (dev, prod)
	@$(AWS_READ_ENV) \
	echo "$(CYAN)Planning $(GREEN)$$ENV$(NC)"; \
	terraform -chdir=$(AWS_TF_DIR) plan

.PHONY: aws-tf-apply
aws-tf-apply: ## Run terraform apply for an AWS environment (dev, prod)
	@$(AWS_READ_ENV) \
	echo "$(CYAN)Applying $(GREEN)$$ENV$(NC)"; \
	terraform -chdir=$(AWS_TF_DIR) apply

.PHONY: aws-tf-fmt
aws-tf-fmt: ## Run terraform fmt on all AWS environments and modules
	@echo "$(CYAN)Formatting aws/terraform (environments and modules)$(NC)"; \
	terraform -chdir=aws/terraform fmt -recursive

.PHONY: aws-tf-validate
aws-tf-validate: ## Run terraform validate for an AWS environment (dev, prod)
	@$(AWS_READ_ENV) \
	echo "$(CYAN)Validating $(GREEN)$$ENV$(NC)"; \
	terraform -chdir=$(AWS_TF_DIR) validate
