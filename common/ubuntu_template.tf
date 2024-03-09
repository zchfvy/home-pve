resource "proxmox_virtual_environment_download_file" "ubuntu_container_template" {
  content_type       = "vztmpl"
  datastore_id       = "local"
  node_name          = var.proxmox_node_name
  url                = "https://cloud-images.ubuntu.com/releases/22.04/release-20231211/ubuntu-22.04-server-cloudimg-amd64-root.tar.xz"
  checksum           = "c9997dcfea5d826fd04871f960c513665f2e87dd7450bba99f68a97e60e4586e"
  checksum_algorithm = "sha256"
  upload_timeout     = 4444
}
