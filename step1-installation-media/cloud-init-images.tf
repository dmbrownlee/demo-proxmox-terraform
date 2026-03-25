variable "cloud_init_storage" {
  type = object({
    node_name = string,
    datastore_id = string
  })
}

variable "iso_storage" {
  type = object({
    node_name = string,
    datastore_id = string
  })
}

variable "cloud_init_images" {
  description = "Map of cloud-init image files to download"
  type = map(object({
    file_name = string,
    url       = string
  }))
}

variable "iso_media" {
  description = "Map of cloud-init image files to download"
  type = map(object({
    file_name = string,
    url       = string
  }))
}

resource "proxmox_virtual_environment_download_file" "cloud_init_images" {
  for_each     = var.cloud_init_images
  content_type = "import"
  overwrite    = true
  datastore_id = var.cloud_init_storage.datastore_id
  file_name    = each.value.file_name
  node_name    = var.cloud_init_storage.node_name
  url          = each.value.url
}

resource "proxmox_virtual_environment_download_file" "iso_media" {
  for_each     = var.iso_media
  content_type = "iso"
  overwrite    = true
  datastore_id = var.iso_storage.datastore_id
  file_name    = each.value.file_name
  node_name    = var.iso_storage.node_name
  url          = each.value.url
}
