module "vm_immich" {
  source = "../../modules/vm_common"

  node_name = "immich"
  
  proxmox_node_name = var.proxmox_node_name
  cpu_cores = 4
  disk_size = 16
  dedicated_memory = 4096
}
