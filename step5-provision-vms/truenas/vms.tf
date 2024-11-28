###############################################################################
###############################################################################
##
##  Variable Definitions
##
###############################################################################
###############################################################################

# Note: This file only defines the variables available.  The values for these
#       variables are assigned in the vms.auto.tfvars file.

variable "vms" {
  description = "The list of Proxmox VMs"
  type = list(object({
    vm_id            = number,
    hostname         = string,
    role             = string,
    pve_node         = string,
    iso_image        = string,
    hardware = object({
      cpu       = object({
        cores = number,
        type  = string,
      })
      memory    = number,
      disks     = list(object({
        datastore_id = string,
        interface    = string,
        size         = number
      }))
      network_devices = list(object({
        interface    = string,
        mac_address  = string,
        vlan_id      = number,
      }))
    })
  }))
}

###############################################################################
###############################################################################
##
##  Resource Definitions
##
###############################################################################
###############################################################################

resource "proxmox_virtual_environment_vm" "lab_vms" {
  depends_on = [
    proxmox_virtual_environment_network_linux_vlan.vlans,
  ]
  for_each    = { for vm in var.vms : vm.hostname => vm }
  name        = each.key
  description = "Managed by Terraform"
  #tags        = ["terraform", each.value.cloud_init_image, each.value.role]
  tags        = ["terraform", each.value.role]
  node_name   = each.value.pve_node
  vm_id       = each.value.vm_id

  bios = "ovmf"
  boot_order = ["virtio0","ide0"]
  cdrom {
    enabled = true
    interface = "ide0"
    file_id = each.value.iso_image
  }
  cpu {
    sockets = 1
    cores   = each.value.hardware.cpu.cores
    type    = each.value.hardware.cpu.type
  }
  dynamic "disk" {
    for_each = each.value.hardware.disks
    content {
      datastore_id = disk.value.datastore_id
      interface    = disk.value.interface
      size         = disk.value.size
      #discard      = "on"
      file_format  = "raw"
      iothread     = true
      #ssd          = true
    }
  }
  efi_disk {
    datastore_id = "local-lvm"
    file_format  = "raw"
  }
  machine = "q35"
  memory {
    dedicated = each.value.hardware.memory
    floating  = each.value.hardware.memory
  }
  dynamic "network_device" {
    for_each = each.value.hardware.network_devices
    content {
      bridge      = network_device.value.interface
      mac_address = network_device.value.mac_address
      vlan_id     = network_device.value.vlan_id
    }
  }
  on_boot = true
  scsi_hardware = "virtio-scsi-single"
  serial_device {}
  vga {
    type = "qxl"
  }
}
