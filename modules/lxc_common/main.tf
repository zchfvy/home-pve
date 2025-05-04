
resource "proxmox_virtual_environment_container" "ubuntu_container" {
  description = var.node_name
  node_name = var.proxmox_node_name

  initialization {
    hostname = var.node_name

    dns {
      domain = var.internal_dns_root
      servers = ["192.168.1.253"]
    }
    ip_config {
      ipv4 {
        address = var.node_ip
        # gateway = "192.168.1.254"  # TODO: set this if node ip is dhcp
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
    # template_file_id = proxmox_virtual_environment_download_file.ubuntu_container_template.id
    template_file_id = "local:vztmpl/ubuntu-22.04-server-cloudimg-amd64-root.tar.xz"
    type             = "ubuntu"
  }

  disk {
    datastore_id = "local-lvm"
    size = var.disk_size
  }

  cpu {
    cores = var.cpu_cores
  }

  memory {
    dedicated = var.dedicated_memory
  }

  features {
    // Required to allow mounting
    mount = ["nfs"]
    nesting = true
  }

  unprivileged = var.privileged == false ? true : false

  dynamic "device_passthrough" {
    for_each = var.passthrough_video == true ? toset([1]) : toset([])

    content {
      path = "/dev/dri/renderD128"
      gid  = var.passthrough_video_group
    }
  }
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
  filename = "${path.cwd}/key.pem"
  file_permission = "0600"
}

resource "ansible_host" "ubuntu_host" {
  name = var.node_name
  groups = [var.node_name]
  variables = {
    ansible_host = var.node_ip == "dhcp" ? "${var.node_name}.${var.internal_dns_root}" : var.node_ip
    ansible_user = "root"
    ansible_ssh_private_key_file = local_file.private_key.filename
    ansible_password = random_password.ubuntu_container_password.result
    ansible_ssh_common_args = "-o StrictHostKeyChecking=no"
  }
}
