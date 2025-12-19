# Homeserver Stack Cleanup & Improvement Plan

## Current Architecture Analysis
Your homeserver uses a **Terraform + Ansible** approach with:
- **Terraform/Terragrunt**: Infrastructure provisioning (Proxmox VMs/LXCs)
- **Ansible**: Configuration management and application deployment
- **Directory Structure**: 12 apps (immich, jellyfin, nextcloud, nginx, paperless, plex, portal, qbittorent, servarr, etc.)

## Key Issues Identified

### 1. **Massive Code Duplication**
- Docker installation repeated in ~6 playbooks (identical 30+ line blocks)
- NFS mounting logic duplicated across multiple services
- Systemd service creation patterns repeated extensively
- User/group creation logic duplicated

### 2. **Inconsistent Patterns**
- Mixed approaches: Some apps use Docker Compose, others manual installs
- Inconsistent naming: `docker-compose` vs `docker compose` commands
- Variable hardcoded values (URLs, ports, paths) scattered throughout

### 3. **Poor Maintainability**
- No shared Ansible roles or common modules
- Secrets management unclear (vault.yml + creds.age)
- Configuration drift potential between similar services
- Missing error handling and idempotency checks

### 4. **Security Concerns**
- Services running as root in some cases
- Hardcoded credentials in some templates
- Inconsistent user management patterns

## Improvement Plan

### Phase 1: Create Ansible Role Structure
- Extract common patterns into reusable Ansible roles:
  - `docker_install` role
  - `nfs_mount` role  
  - `systemd_service` role
  - `servarr_app` role (for Radarr/Sonarr/Prowlarr)

### Phase 2: Standardize Configuration
- Create consistent variable definitions
- Implement proper secrets management
- Standardize Docker Compose deployment patterns
- Add proper error handling and validation

### Phase 3: Documentation & Tooling
- Create comprehensive README with setup instructions
- Add Makefile for common operations
- Implement proper backup/restore procedures
- Add health check automation

### Phase 4: Security Hardening
- Review and fix service user permissions
- Implement proper secret rotation
- Add network security configurations
- Audit exposed ports and access patterns

**Estimated effort**: 2-3 days for significant improvements
**Benefits**: ~60% reduction in code duplication, much easier maintenance, better security posture