variable "vm_templates" {
  description = "Map of VM template objects keyed on template name"
  type = map(object({
    file_name = string,
    node_name = string,
    vm_id     = number,
    datastore = string,
    disk_size = number
  }))
}

resource "proxmox_virtual_environment_vm" "vm_templates" {
  for_each        = var.vm_templates
  acpi            = true
  bios            = "seabios"
  keyboard_layout = "en-us"
  migrate         = false
  name            = each.key
  node_name       = each.value.node_name
  on_boot         = false
  reboot          = false
  scsi_hardware   = "virtio-scsi-single"
  started         = false
  tablet_device   = true
  tags = [
    each.key,
    "terraform",
    "cloud_init_template",
  ]
  template            = true
  timeout_clone       = 1800
  timeout_create      = 1800
  timeout_migrate     = 1800
  timeout_reboot      = 1800
  timeout_shutdown_vm = 1800
  timeout_start_vm    = 1800
  timeout_stop_vm     = 300
  vm_id               = each.value.vm_id

  agent {
    enabled = false
    timeout = "15m"
    trim    = false
    type    = "virtio"
  }

  cpu {
    cores      = 2
    flags      = []
    hotplugged = 0
    sockets    = 1
    type       = "x86-64-v2-AES"
  }

  disk {
    datastore_id = each.value.datastore
    discard      = "on"
    file_id      = each.value.file_name
    interface    = "scsi0"
    iothread     = true
    size         = each.value.disk_size
    ssd          = true
  }

  initialization {
    datastore_id = "local-lvm"
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
  }

  memory {
    dedicated = 2048
    floating  = 2048
    shared    = 0
  }

  network_device {
    bridge     = "vmbr0"
    enabled    = true
    firewall   = true
    model      = "virtio"
    mtu        = 0
    queues     = 0
    rate_limit = 0
  }

  operating_system {
    type = "l26"
  }

  serial_device {
    device = "socket"
  }

  vga {
    memory = 16
    type   = "qxl"
  }
}
