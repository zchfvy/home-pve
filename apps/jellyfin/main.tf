module "lxc_jellyfin" {
  source = "../../modules/lxc_common"

  node_name = "jellyfin"
  
  proxmox_node_name = var.proxmox_node_name

  disk_size = 16
  cpu_cores = 2
  dedicated_memory = 2048

  passthrough_video = true
  passthrough_video_group = 110
}
