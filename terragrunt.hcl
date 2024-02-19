terraform {
    extra_arguments "use_tfvars" {
        commands = ["apply", "plan"]
        arguments = ["-var-file=${get_parent_terragrunt_dir()}/terraform.tfvars"]
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
      version = "0.46.4"
    }
    ansible = {
      source = "ansible/ansible"
      version = "1.1.0"
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
EOF

}
