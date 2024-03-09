module "lxc_radarr" {
  source = "../../modules/lxc_common"

  node_name = "radarr"
  
  proxmox_node_name = var.proxmox_node_name
}
