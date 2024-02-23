locals {
  node_ip = "192.168.1.40"
}


resource "proxmox_virtual_environment_container" "ubuntu_container" {
  description = "Plex"
  node_name = var.proxmox_node_name

  initialization {
    hostname = "plex"

    dns {
      domain = "home.arpa"
      servers = ["192.168.1.253"]
    }
    ip_config {
      ipv4 {
        address = "${local.node_ip}/24"
        gateway = "192.168.1.254"
      }
    }

    user_account {
      keys = [
        trimspace(tls_private_key.ubuntu_container_key.public_key_openssh)
      ]
      password = random_password.ubuntu_container_password.result
    }
  }

  network_interface {
    name = "veth0"
  }

  operating_system {
    template_file_id = proxmox_virtual_environment_download_file.ubuntu_container_template.id
    type             = "ubuntu"
  }

  disk {
    datastore_id = "local-lvm"
  }

  memory {
    dedicated = 1024
  }

  features {
    // Required to allow mounting
    mount = ["nfs"]
  }
}

resource "proxmox_virtual_environment_download_file" "ubuntu_container_template" {
  content_type       = "vztmpl"
  datastore_id       = "local"
  node_name          = var.proxmox_node_name
  url                = "https://cloud-images.ubuntu.com/releases/22.04/release-20231211/ubuntu-22.04-server-cloudimg-amd64-root.tar.xz"
  checksum           = "c9997dcfea5d826fd04871f960c513665f2e87dd7450bba99f68a97e60e4586e"
  checksum_algorithm = "sha256"
  upload_timeout     = 4444
}

resource "random_password" "ubuntu_container_password" {
  length           = 16
  override_special = "_%@"
  special          = true
}

resource "tls_private_key" "ubuntu_container_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

output "ubuntu_container_password" {
  value     = random_password.ubuntu_container_password.result
  sensitive = true
}

# TODO : just use a global key file for terraform
resource "local_file" "private_key" {
  content = tls_private_key.ubuntu_container_key.private_key_pem
  filename = "${path.module}/key.pem"
  file_permission = "0600"
}

resource "ansible_host" "ubuntu_host" {
  name = "plex"
  groups = ["plex"]
  variables = {
    ansible_host = local.node_ip
    ansible_user = "root"
    ansible_ssh_private_key_file = local_file.private_key.filename
    ansible_password = random_password.ubuntu_container_password.result
    ansible_ssh_common_args = "-o StrictHostKeyChecking=no"
  }
}
