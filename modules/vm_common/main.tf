
resource "proxmox_virtual_environment_vm" "ubuntu_vm" {
  name = var.node_name
  node_name = var.proxmox_node_name

  initialization {
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
      username = "ubuntu"
      keys = [
        trimspace(tls_private_key.ubuntu_vm_key.public_key_openssh)
      ]
      password = random_password.ubuntu_vm_password.result
    }
  }

  operating_system {
    # template_file_id = proxmox_virtual_environment_download_file.ubuntu_vm_template.id
    type             = "l26"
  }

  disk {
    datastore_id = "local-lvm"
    interface = "scsi0"
    size = var.disk_size
    file_id = "local:iso/jammy-server-cloudimg-amd64.img"
  }

  cpu {
    cores = var.cpu_cores
  }

  memory {
    dedicated = var.dedicated_memory
  }

  network_device {
    enabled = true
    bridge = "vmbr0"
  }
}

resource "random_password" "ubuntu_vm_password" {
  length           = 16
  override_special = "_%@"
  special          = true
}

resource "tls_private_key" "ubuntu_vm_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

output "ubuntu_vm_password" {
  value     = random_password.ubuntu_vm_password.result
  sensitive = true
}

# TODO : just use a global key file for terraform
resource "local_file" "private_key" {
  content = tls_private_key.ubuntu_vm_key.private_key_pem
  filename = "${path.cwd}/key.pem"
  file_permission = "0600"
}

resource "ansible_host" "ubuntu_host" {
  name = var.node_name
  groups = [var.node_name]
  variables = {
    ansible_host = var.node_ip == "dhcp" ? "${var.node_name}.${var.internal_dns_root}" : var.node_ip
    ansible_user = "ubuntu"
    ansible_ssh_private_key_file = local_file.private_key.filename
    ansible_password = random_password.ubuntu_vm_password.result
    ansible_ssh_common_args = "-o StrictHostKeyChecking=no"
  }
}
