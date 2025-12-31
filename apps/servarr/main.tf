module "lxc_servarr" {
  source = "../../modules/lxc_common"

  node_name = "servarr"

  proxmox_node_name    = var.proxmox_node_name
  disk_size            = 16
  dedicated_memory     = 1024
  ssh_public_key_file  = var.ssh_public_key_file
  ssh_private_key_file = var.ssh_private_key_file
}
