module "vm_paperless" {
  source = "../../modules/vm_common"

  node_name = "paperless"
  
  proxmox_node_name = var.proxmox_node_name
  cpu_cores = 2
  disk_size = 16
  dedicated_memory = 2048
}
