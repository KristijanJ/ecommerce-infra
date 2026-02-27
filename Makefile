# Colors for output
GREEN = \033[0;32m
YELLOW = \033[1;33m
RED = \033[0;31m
CYAN = \033[0;36m
NC = \033[0m # No Color

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
start-local: ## Start the full local environment (cluster + ArgoCD + monitoring)
	@echo "$(CYAN)Starting local environment...$(NC)"
	@docker-compose -f local/docker-compose.yml up -d
	@echo "$(CYAN)Docker containers started:$(NC)"
	@docker ps | grep -E "ecommerce-postgres|ecommerce-redis"
	@echo "$(GREEN)$(CHECK) Local environment ready$(NC)"