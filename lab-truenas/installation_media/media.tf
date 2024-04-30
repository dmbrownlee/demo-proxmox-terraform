###############################################################################
###############################################################################
##
##  Variable Definitions
##
###############################################################################
###############################################################################

# Note: This file only defines the variables available.  The values for these
#       variables are assigned in the vms.auto.tfvars file.

variable "proxmox_iso_datastore" {
  description = "The Proxmox node and storage name containing ISO images"
  type        = object({
    node_name    = string,
    datastore_id = string,
  })
}

variable "iso_images" {
  description = "A list of ISO files to download"
  type        = list(object({
    checksum  = string,
    checksum_algorithm = string,
    file_name = string,
    url      = string,
  }))
}

###############################################################################
###############################################################################
##
##  Resource Definitions
##
###############################################################################
###############################################################################

resource "proxmox_virtual_environment_download_file" "iso_images" {
  for_each     = { for iso in var.iso_images: iso.file_name => iso }
  checksum     = each.value.checksum
  checksum_algorithm     = each.value.checksum_algorithm
  content_type = "iso"
  datastore_id = var.proxmox_iso_datastore.datastore_id
  file_name    = each.value.file_name
  node_name    = var.proxmox_iso_datastore.node_name
  #overwrite    = true
  url          = each.value.url
}
