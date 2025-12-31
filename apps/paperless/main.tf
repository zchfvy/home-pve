module "vm_paperless" {
  source = "../../modules/vm_common"

  node_name = "paperless"

  proxmox_node_name    = var.proxmox_node_name
  cpu_cores            = 4
  disk_size            = 16
  dedicated_memory     = 2048
  ssh_public_key_file  = var.ssh_public_key_file
  ssh_private_key_file = var.ssh_private_key_file
}
