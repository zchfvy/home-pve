terraform {
    extra_arguments "use_tfvars" {
        commands = ["apply", "plan", "destroy"]
        arguments = ["-var-file=${get_parent_terragrunt_dir()}/terraform.tfvars"]
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
EOF

}
