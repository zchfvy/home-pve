SHELL=/bin/bash

# =============================================================================
# Service Configuration
# =============================================================================

# All services - single source of truth
SERVICES = immich paperless portal qbittorent plex jellyfin servarr

# =============================================================================
# Tool Configuration
# =============================================================================

# Terragrunt wrapper (handles secret decryption)
TERRAGRUNT = ../../secrets/scripts/terragrunt-with-secrets.sh

# Ansible configuration
ANSIBLE_VAULT_ARGS = --ask-vault-pass -e @../../secrets/ansible/group_vars/all/vault.yml -e @../../secrets/ansible/group_vars/all/vars.yml
ANSIBLE_BASE = ANSIBLE_ROLES_PATH=../../roles ansible-playbook -i inventory.yml playbook.yml $(ANSIBLE_VAULT_ARGS)
ANSIBLE = $(ANSIBLE_BASE)
ANSIBLE_CHECK = $(ANSIBLE_BASE) --check --diff

# Batch scripts
BATCH_INFRA = ./secrets/scripts/batch-infra.sh
BATCH_ANSIBLE = ./secrets/scripts/batch-ansible.sh
DEPLOY_ALL = ./secrets/scripts/deploy-all.sh

# =============================================================================
# Help (default target)
# =============================================================================

.PHONY: help
help:
	@echo "Homeserver Makefile Targets"
	@echo "==========================="
	@echo ""
	@echo "Individual Service Operations:"
	@echo "  plan-infra-<service>    - Show infrastructure changes (terraform plan)"
	@echo "  deploy-infra-<service>  - Apply infrastructure (terraform apply)"
	@echo "  deploy-app-<service>    - Deploy application (ansible-playbook)"
	@echo "  check-app-<service>     - Dry-run application (ansible --check)"
	@echo "  deploy-<service>        - Full deployment (infra + app)"
	@echo ""
	@echo "Batch Operations (single passphrase prompt):"
	@echo "  plan-infra-all          - Plan all infrastructure"
	@echo "  apply-infra-all         - Apply all infrastructure"
	@echo "  deploy-app-all          - Deploy all applications"
	@echo "  check-app-all           - Dry-run all applications"
	@echo ""
	@echo "Combined Operations:"
	@echo "  plan-all                - Plan infra + check apps"
	@echo "  deploy-all              - Full deployment: plan -> confirm -> apply -> wait -> deploy"
	@echo ""
	@echo "Available services: $(SERVICES)"
	@echo ""
	@echo "Utilities:"
	@echo "  clean-secrets           - Remove decrypted secrets file"
	@echo "  help                    - Show this help message"

# =============================================================================
# Pattern Rules (individual service operations)
# =============================================================================

# Infrastructure plan
.PHONY: plan-infra-%
plan-infra-%:
	cd apps/$* && $(TERRAGRUNT) plan

# Infrastructure apply
.PHONY: deploy-infra-%
deploy-infra-%:
	cd apps/$* && $(TERRAGRUNT) apply

# Application deploy
.PHONY: deploy-app-%
deploy-app-%:
	cd apps/$* && $(ANSIBLE)

# Application check (dry-run)
.PHONY: check-app-%
check-app-%:
	cd apps/$* && $(ANSIBLE_CHECK)

# Full service deployment (infra + app)
.PHONY: deploy-%
deploy-%: deploy-infra-% deploy-app-%
	@echo "Deployed $*"

# =============================================================================
# Batch Operations (single passphrase prompt)
# =============================================================================

.PHONY: plan-infra-all
plan-infra-all:
	@$(BATCH_INFRA) plan $(SERVICES)

.PHONY: apply-infra-all
apply-infra-all:
	@$(BATCH_INFRA) apply $(SERVICES)

.PHONY: deploy-app-all
deploy-app-all:
	@$(BATCH_ANSIBLE) deploy $(SERVICES)

.PHONY: check-app-all
check-app-all:
	@$(BATCH_ANSIBLE) check $(SERVICES)

# =============================================================================
# Combined Operations
# =============================================================================

# Plan everything (infra + apps dry-run)
.PHONY: plan-all
plan-all: plan-infra-all check-app-all

# Full deployment with confirmation
.PHONY: deploy-all
deploy-all:
	@$(DEPLOY_ALL) $(SERVICES)

# Legacy alias
.PHONY: check-all
check-all: check-app-all

# =============================================================================
# Utilities
# =============================================================================

.PHONY: clean-secrets
clean-secrets:
	rm -f secrets/infrastructure.env
