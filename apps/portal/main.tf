module "lxc_portal" {
  source = "../../modules/lxc_common"

  node_name = "portal"
  
  proxmox_node_name = var.proxmox_node_name
}
