SHELL=/bin/bash

# Variables
TERRAGRUNT = ../../secrets/scripts/terragrunt-with-secrets.sh apply
ANSIBLE_VAULT_ARGS = --ask-vault-pass -e @../../secrets/ansible/group_vars/all/vault.yml -e @../../secrets/ansible/group_vars/all/vars.yml
ANSIBLE = ansible-playbook -i inventory.yml playbook.yml $(ANSIBLE_VAULT_ARGS)

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
.PHONY: deploy-app-qbittorrent deploy-app-portal deploy-app-paperless deploy-app-immich
deploy-app-qbittorrent:
	cd apps/qbittorent && $(ANSIBLE)

deploy-app-portal:
	cd apps/portal && $(ANSIBLE)

deploy-app-paperless:
	cd apps/paperless && $(ANSIBLE)

deploy-app-immich:
	cd apps/immich && $(ANSIBLE)

# Full service deployment (infra + app)
.PHONY: deploy-qbittorrent deploy-portal deploy-paperless deploy-immich
deploy-qbittorrent: deploy-infra-qbittorrent deploy-app-qbittorrent
deploy-portal: deploy-infra-portal deploy-app-portal  
deploy-paperless: deploy-infra-paperless deploy-app-paperless
deploy-immich: deploy-infra-immich deploy-app-immich

# Utilities
.PHONY: clean-secrets
clean-secrets:
	rm secrets/infrastructure.env 
