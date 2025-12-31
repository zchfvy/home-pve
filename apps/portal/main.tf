module "lxc_portal" {
  source = "../../modules/lxc_common"

  node_name = "portal"

  proxmox_node_name    = var.proxmox_node_name
  dedicated_memory     = 1024
  disk_size            = 7
  ssh_public_key_file  = var.ssh_public_key_file
  ssh_private_key_file = var.ssh_private_key_file
}
