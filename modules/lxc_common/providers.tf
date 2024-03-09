
terraform {
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
      version = "0.46.4"
    }
    ansible = {
      source = "ansible/ansible"
      version = "1.1.0"
    }
  }
}
