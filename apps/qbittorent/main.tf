module "lxc_qbittorent" {
  source = "../../modules/lxc_common"

  node_name = "qbittorrent"

  proxmox_node_name    = var.proxmox_node_name
  dedicated_memory     = 4096
  ssh_public_key_file  = var.ssh_public_key_file
  ssh_private_key_file = var.ssh_private_key_file
}
