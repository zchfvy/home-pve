module "vm_monitoring" {
  source = "../../modules/vm_common"

  node_name = "monitoring"

  proxmox_node_name    = var.proxmox_node_name
  disk_size            = 16
  cpu_cores            = 2
  dedicated_memory     = 2048
  ssh_public_key_file  = var.ssh_public_key_file
  ssh_private_key_file = var.ssh_private_key_file
}
