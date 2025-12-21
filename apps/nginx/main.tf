module "lxc_nginx" {
  source = "../../modules/lxc_common"

  node_name         = "nginx"
  proxmox_node_name = var.proxmox_node_name

  # Minimal resources - nginx is lightweight
  disk_size        = 4
  cpu_cores        = 1
  dedicated_memory = 512
}
