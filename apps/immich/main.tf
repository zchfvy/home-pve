module "vm_immich" {
  source = "../../modules/vm_common"

  node_name = "immich"

  proxmox_node_name    = var.proxmox_node_name
  cpu_cores            = 4
  disk_size            = 24
  dedicated_memory     = 4096
  ssh_public_key_file  = var.ssh_public_key_file
  ssh_private_key_file = var.ssh_private_key_file
}
