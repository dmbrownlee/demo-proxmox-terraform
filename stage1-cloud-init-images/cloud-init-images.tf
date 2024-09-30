variable "iso_storage" {
  type = object({
    node = string,
    name = string
  })
}

variable "cloud_init_images" {
  description = "Map of cloud-init image files to download"
  type = map(object({
    file_name = string,
    url       = string
  }))
}

resource "proxmox_virtual_environment_download_file" "cloud_init_images" {
  for_each     = var.cloud_init_images
  content_type = "iso"
  overwrite    = true
  datastore_id = var.iso_storage.name
  file_name    = each.value.file_name
  node_name    = var.iso_storage.node
  url          = each.value.url
}
