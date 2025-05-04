
terraform {
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
      version = "0.77.0"
    }
    ansible = {
      source = "ansible/ansible"
      version = "1.3.0"
    }
  }
}
