module "lxc_qbittorent" {
  source = "../../modules/lxc_common"

  node_name = "qbittorrent"
  
  proxmox_node_name = var.proxmox_node_name
}
