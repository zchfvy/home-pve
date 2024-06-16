module "lxc_plex" {
  source = "../../modules/lxc_common"

  node_name = "plex"
  
  proxmox_node_name = var.proxmox_node_name

  disk_size = 16
  cpu_cores = 2
  dedicated_memory = 1024
}
