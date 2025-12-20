SHELL=/bin/bash

# Variables
TERRAGRUNT = ../../secrets/scripts/terragrunt-with-secrets.sh apply
ANSIBLE_VAULT_ARGS = --ask-vault-pass -e @../../secrets/ansible/group_vars/all/vault.yml -e @../../secrets/ansible/group_vars/all/vars.yml
ANSIBLE_BASE = ANSIBLE_ROLES_PATH=../../roles ansible-playbook -i inventory.yml playbook.yml $(ANSIBLE_VAULT_ARGS)
ANSIBLE = $(ANSIBLE_BASE)
ANSIBLE_CHECK = $(ANSIBLE_BASE) --check --diff

# Help target (default)
.PHONY: help
help:
	@echo "Homeserver Makefile Targets"
	@echo "==========================="
	@echo ""
	@echo "Infrastructure (Terraform/Terragrunt):"
	@echo "  deploy-infra-<service>  - Provision infrastructure for a service"
	@echo ""
	@echo "Applications (Ansible):"
	@echo "  deploy-app-<service>    - Configure and deploy application"
	@echo "  check-app-<service>     - Dry-run (check mode) for application"
	@echo ""
	@echo "Full Deployment:"
	@echo "  deploy-<service>        - Deploy both infrastructure and application"
	@echo ""
	@echo "Available services: qbittorrent, portal, paperless, immich, servarr, jellyfin, plex"
	@echo ""
	@echo "Utilities:"
	@echo "  check-all               - Run check mode on all services"
	@echo "  clean-secrets           - Remove decrypted secrets file"
	@echo "  help                    - Show this help message"

# Infrastructure deployment (Terraform/Terragrunt)
.PHONY: deploy-infra-qbittorrent deploy-infra-portal deploy-infra-paperless deploy-infra-immich
deploy-infra-qbittorrent:
	cd apps/qbittorent && $(TERRAGRUNT)

deploy-infra-portal:
	cd apps/portal && $(TERRAGRUNT)

deploy-infra-paperless:
	cd apps/paperless && $(TERRAGRUNT)

deploy-infra-immich:
	cd apps/immich && $(TERRAGRUNT)

# Application deployment (Ansible)
.PHONY: deploy-app-qbittorrent deploy-app-portal deploy-app-paperless deploy-app-immich deploy-app-servarr deploy-app-jellyfin deploy-app-plex
deploy-app-qbittorrent:
	cd apps/qbittorent && $(ANSIBLE)

deploy-app-portal:
	cd apps/portal && $(ANSIBLE)

deploy-app-paperless:
	cd apps/paperless && $(ANSIBLE)

deploy-app-immich:
	cd apps/immich && $(ANSIBLE)

deploy-app-servarr:
	cd apps/servarr && $(ANSIBLE)

deploy-app-jellyfin:
	cd apps/jellyfin && $(ANSIBLE)

deploy-app-plex:
	cd apps/plex && $(ANSIBLE)

# Full service deployment (infra + app)
.PHONY: deploy-qbittorrent deploy-portal deploy-paperless deploy-immich
deploy-qbittorrent: deploy-infra-qbittorrent deploy-app-qbittorrent
deploy-portal: deploy-infra-portal deploy-app-portal  
deploy-paperless: deploy-infra-paperless deploy-app-paperless
deploy-immich: deploy-infra-immich deploy-app-immich

# Dry run / check mode (validates changes without applying)
.PHONY: check-app-qbittorrent check-app-portal check-app-paperless check-app-immich check-app-servarr check-app-jellyfin check-app-plex check-all
check-app-qbittorrent:
	cd apps/qbittorent && $(ANSIBLE_CHECK)

check-app-portal:
	cd apps/portal && $(ANSIBLE_CHECK)

check-app-paperless:
	cd apps/paperless && $(ANSIBLE_CHECK)

check-app-immich:
	cd apps/immich && $(ANSIBLE_CHECK)

check-app-servarr:
	cd apps/servarr && $(ANSIBLE_CHECK)

check-app-jellyfin:
	cd apps/jellyfin && $(ANSIBLE_CHECK)

check-app-plex:
	cd apps/plex && $(ANSIBLE_CHECK)

check-all: check-app-immich check-app-paperless check-app-servarr check-app-jellyfin check-app-plex check-app-qbittorrent check-app-portal

# Utilities
.PHONY: clean-secrets
clean-secrets:
	rm secrets/infrastructure.env
