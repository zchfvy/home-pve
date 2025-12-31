variable "node_name" {
}
variable "node_ip" {
  description = "Set to give a static IP address to the node, otherwise uses dhcp"
  default = "dhcp"
}
variable "dedicated_memory" {
  default = 512
}

variable "proxmox_node_name" {
}

variable "internal_dns_root" {
  default = "home.arpa"
}

variable "disk_size" {
  default = 4
}

variable "cpu_cores" {
  default = 1
}

variable "privileged" {
  default = true
}

variable "passthrough_video" {
  default = false
}

variable "passthrough_video_group" {
  default = null
}

variable "ssh_public_key_file" {
  description = "Path to SSH public key file"
  default     = "~/.ssh/homeserver.pub"
  sensitive   = true
}

variable "ssh_private_key_file" {
  description = "Path to SSH private key file (for ansible)"
  default     = "~/.ssh/homeserver"
  sensitive   = true
}
