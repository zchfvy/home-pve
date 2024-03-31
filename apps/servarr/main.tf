module "lxc_servarr" {
  source = "../../modules/lxc_common"

  node_name = "servarr"
  
  proxmox_node_name = var.proxmox_node_name
}
