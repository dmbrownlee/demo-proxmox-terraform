resource "proxmox_virtual_environment_download_file" "cloud_init_images" {
  depends_on = [
    proxmox_virtual_environment_network_linux_vlan.vlans
  ]
  for_each     = toset(keys(var.cloud_init_images))
  content_type = "iso"
  overwrite    = true
  datastore_id = var.iso_storage.name
  file_name    = var.cloud_init_images[each.value].file_name
  node_name    = var.iso_storage.node
  url          = var.cloud_init_images[each.value].url
}

resource "proxmox_virtual_environment_vm" "vm_templates" {
  depends_on = [
    proxmox_virtual_environment_download_file.cloud_init_images,
  ]
  for_each        = var.vm_templates
  acpi            = true
  bios            = "seabios"
  keyboard_layout = "en-us"
  migrate         = false
  name            = each.key
  node_name       = var.vm_template_storage.node
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
  timeout_move_disk   = 1800
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
    architecture = "x86_64"
    cores        = 2
    flags        = []
    hotplugged   = 0
    sockets      = 1
    type         = "x86-64-v2-AES"
  }

  disk {
    datastore_id = var.vm_template_storage.name
    discard      = "on"
    file_id      = proxmox_virtual_environment_download_file.cloud_init_images[each.value.cloud_init_image].id
    interface    = "scsi0"
    iothread     = true
    size         = 2
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
    vlan_id    = var.vlans[index(var.vlans.*.comment, "PROVISIONING")].vlan_id
  }

  operating_system {
    type = "l26"
  }

  vga {
    enabled = true
    memory  = 16
    type    = "qxl"
  }
}
