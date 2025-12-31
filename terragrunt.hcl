# Remote state on NFS share
remote_state {
    backend = "local"
    config = {
        path = "/mnt/oddesy/terraform-state/homeserver/${path_relative_to_include()}/terraform.tfstate"
    }
    generate = {
        path      = "backend.tf"
        if_exists = "overwrite_terragrunt"
    }
}

terraform {
    extra_arguments "use_tfvars" {
        commands = ["apply", "plan", "destroy", "import"]
        arguments = ["-var-file=${get_parent_terragrunt_dir()}/terraform.tfvars"]
    }

    # Fail fast if NFS share is not mounted
    before_hook "check_nfs_mount" {
        commands = ["init", "plan", "apply", "destroy", "import"]
        execute  = ["bash", "-c", "mountpoint -q /mnt/oddesy || (echo 'ERROR: /mnt/oddesy is not mounted. Mount NFS share first.' >&2 && exit 1)"]
    }

    before_hook "update_providers" {
        commands = ["plan", "apply"]
        execute = ["terraform", "init", "-upgrade"]
        run_on_error = false
    }
}

generate "provider" {
    path = "provider.tf"
    if_exists = "overwrite_terragrunt"

    contents = <<EOF
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
provider "proxmox" {
  endpoint = var.proxmox_url
  insecure = true
}
provider "ansible" {
}



variable "proxmox_url" {}
variable "proxmox_node_name" {}
variable "ssh_public_key_file" {
  sensitive = true
}
variable "ssh_private_key_file" {
  sensitive = true
}
EOF

}
