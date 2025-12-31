module "lxc_plex" {
  source = "../../modules/lxc_common"

  node_name = "plex"

  proxmox_node_name    = var.proxmox_node_name
  disk_size            = 16
  cpu_cores            = 2
  dedicated_memory     = 2048
  ssh_public_key_file  = var.ssh_public_key_file
  ssh_private_key_file = var.ssh_private_key_file
}
