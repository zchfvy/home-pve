module "lxc_nginx" {
  source = "../../modules/lxc_common"

  node_name            = "nginx"
  proxmox_node_name    = var.proxmox_node_name
  ssh_public_key_file  = var.ssh_public_key_file
  ssh_private_key_file = var.ssh_private_key_file

  # Minimal resources - nginx is lightweight
  disk_size        = 4
  cpu_cores        = 1
  dedicated_memory = 512
}
