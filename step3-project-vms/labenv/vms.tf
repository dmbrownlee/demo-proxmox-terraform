###############################################################################
###############################################################################
##
##  Variable Definitions
##
###############################################################################
###############################################################################
variable "ci_user" {
  description = "Default cloud-init account"
  type        = string
}

variable "ci_password" {
  description = "Password for cloud-init account"
  type        = string
  sensitive   = true
}

variable "sleep_seconds_before_remote_provisioning" {
  description = "The number of seconds to wait after booting before trying SSH"
  type        = number
  default     = 30
}

variable "vm_template_storage" {
  description = "Proxmox node and storage name where VM templates are stored"
  type = object({
    node = string,
    name = string
  })
}

variable "vlans" {
  description = "Map of VLAN objects indexed on name"
  type = list(object({
    vlan_id          = number,
    comment          = string
    ipv4_gateway     = string,
    ipv4_dns_servers = list(string)
  }))
}

variable "laptops" {
  description = "A list of VMs to be cloned from cloud-init images"
  type = list(object({
    vm_id            = number,
    hostname         = string,
    pve_node         = string,
    iso_image        = string,
    boot_order       = list(string),
    cloud_init_image = string,
    ipv4_address     = string,
    domain           = string,
    bios             = string,
    dns = object({
      zone = string,
      rr_a = string,
    })
    hardware = object({
      cpu = object({
        cores = number,
        type  = string,
      })
      disks = list(object({
        datastore_id = string,
        interface    = string,
        size         = number
      }))
      memory = number,
      network_devices = list(object({
        disconnected = bool,
        interface    = string,
        mac_address  = string,
        vlan_id      = number,
      }))
      vga = object({
        memory = number,
        type   = string,
      })
    })
  }))
}

variable "vms" {
  description = "A list of VMs to be created without an installed OS"
  type = list(object({
    vm_id      = number,
    hostname   = string,
    pve_node   = string,
    iso_image  = string,
    boot_order = list(string),
    bios       = string,
    hardware = object({
      cpu = object({
        cores = number,
        type  = string,
      })
      disks = list(object({
        datastore_id = string,
        interface    = string,
        size         = number,
        serial       = string
      }))
      memory = number,
      network_devices = list(object({
        disconnected = bool,
        interface    = string,
        mac_address  = string,
        vlan_id      = number,
      }))
      vga = object({
        memory = number,
        type   = string,
      })
    })
  }))
}

variable "media_mapping" {
  description = "A mapping for USB recovery media"
  type = object({
    comment = string,
    name    = string,
    id      = string,
    node    = string,
  })
}

###############################################################################
###############################################################################
##
##  Resource Definitions
##
###############################################################################
###############################################################################
resource "dns_a_record_set" "laptops" {
  for_each  = { for vm in var.laptops : vm.hostname => vm }
  zone      = "${each.value.dns.zone}."
  name      = each.key
  addresses = ["${each.value.dns.rr_a}"]
  ttl       = 300
}


resource "ansible_host" "laptops" {
  for_each = { for vm in var.laptops : vm.hostname => vm }
  name     = each.key
  groups   = ["admin_laptop"]
  depends_on = [
    resource.proxmox_virtual_environment_vm.laptops,
    resource.proxmox_virtual_environment_hardware_mapping_usb.SanDisk
  ]
}


resource "proxmox_virtual_environment_hardware_mapping_usb" "SanDisk" {
  comment = var.media_mapping.comment
  name    = var.media_mapping.name
  map = [
    {
      id   = var.media_mapping.id
      node = var.media_mapping.node
    },
  ]
}


resource "proxmox_virtual_environment_vm" "laptops" {
  depends_on = [
    resource.dns_a_record_set.laptops,
    resource.proxmox_virtual_environment_hardware_mapping_usb.SanDisk
  ]
  lifecycle {
    ignore_changes = [
      started,
      mac_addresses,
      cdrom[0].file_id,
      network_device[0].disconnected,
    network_device[1].disconnected]
  }
  for_each      = { for vm in var.laptops : vm.hostname => vm }
  acpi          = true
  bios          = each.value.bios # [ovmf/seabios]
  boot_order    = each.value.boot_order
  description   = "Managed by Terraform"
  mac_addresses = []
  machine       = "q35"
  name          = each.key
  node_name     = each.value.pve_node
  protection    = false
  scsi_hardware = "virtio-scsi-single"
  started       = true
  tablet_device = true
  tags          = ["${terraform.workspace}", each.value.cloud_init_image]
  template      = false
  vm_id         = each.value.vm_id

  cdrom {
    file_id   = each.value.iso_image
    interface = "ide2"
  }

  clone {
    datastore_id = var.vm_template_storage.name
    node_name    = var.vm_template_storage.node
    vm_id        = data.proxmox_virtual_environment_vms.cloud_init_template.vms[index(data.proxmox_virtual_environment_vms.cloud_init_template.vms[*].name, each.value.cloud_init_image)].vm_id
    full         = true
  }

  cpu {
    cores      = each.value.hardware.cpu.cores
    flags      = []
    hotplugged = 0
    limit      = 0
    numa       = false
    sockets    = 1
    type       = each.value.hardware.cpu.type
    units      = 1024
  }

  dynamic "disk" {
    for_each = each.value.hardware.disks
    content {
      aio          = "io_uring"
      backup       = false
      cache        = "none"
      datastore_id = disk.value.datastore_id
      discard      = "on"
      file_format  = "raw"
      interface    = disk.value.interface
      iothread     = true
      replicate    = true
      size         = disk.value.size
      ssd          = false
    }
  }

  # dns = {
  #   zone = "site1.thebrownleefamily.net"
  #   rr_a = "10.48.16.175"
  # }

  efi_disk {
    datastore_id      = "local-lvm"
    file_format       = "raw"
    pre_enrolled_keys = true
    type              = "4m"
  }

  initialization {
    datastore_id = "local-lvm"
    dns {
      servers = var.vlans[index(var.vlans.*.vlan_id, each.value.hardware.network_devices[0].vlan_id)].ipv4_dns_servers
      domain  = each.value.domain
    }
    ip_config {
      ipv4 {
        address = each.value.ipv4_address
        gateway = var.vlans[index(var.vlans.*.vlan_id, each.value.hardware.network_devices[0].vlan_id)].ipv4_gateway
      }
    }
    user_account {
      username = var.ci_user
      password = var.ci_password
      keys     = [trimspace(data.local_file.ci_ssh_public_key_file.content)]
    }
  }

  memory {
    dedicated      = each.value.hardware.memory
    floating       = each.value.hardware.memory
    keep_hugepages = false
    shared         = 0
  }

  dynamic "network_device" {
    for_each = each.value.hardware.network_devices
    content {
      bridge       = network_device.value.interface
      disconnected = network_device.value.disconnected
      enabled      = true
      firewall     = false
      model        = "virtio"
      mac_address  = network_device.value.mac_address
      mtu          = 0
      queues       = 0
      rate_limit   = 0
      vlan_id      = network_device.value.vlan_id
    }
  }

  on_boot = false

  connection {
    type  = "ssh"
    user  = var.ci_user
    agent = true
    host  = "${self.name}.${each.value.domain}"
  }

  provisioner "local-exec" {
    command = "sleep ${var.sleep_seconds_before_remote_provisioning}"
  }

  provisioner "remote-exec" {
    inline = ["hostnamectl"]
  }

  startup {
    order = 1
  }

  vga {
    memory = each.value.hardware.vga.memory
    type   = each.value.hardware.vga.type
  }

  operating_system {
    type = "l26"
  }

  reboot              = false
  reboot_after_update = false
  serial_device {}

  tpm_state {
    datastore_id = "local-lvm"
    version      = "v2.0"
  }

  usb {
    mapping = "SanDisk"
    usb3    = true
  }
}


resource "proxmox_virtual_environment_vm" "vms" {
  lifecycle {
    ignore_changes = [
      started,
      mac_addresses,
      cdrom[0].file_id,
      network_device[0].disconnected,
    network_device[1].disconnected]
  }
  for_each      = { for vm in var.vms : vm.hostname => vm }
  acpi          = true
  bios          = each.value.bios # [ovmf/seabios]
  boot_order    = each.value.boot_order
  description   = "Managed by Terraform"
  mac_addresses = []
  machine       = "q35"
  name          = each.key
  node_name     = each.value.pve_node
  protection    = false
  scsi_hardware = "virtio-scsi-single"
  started       = false
  tablet_device = true
  tags          = ["${terraform.workspace}"]
  #tags          = ["${terraform.workspace}", each.value.cloud_init_image]
  template = false
  vm_id    = each.value.vm_id

  cdrom {
    file_id   = each.value.iso_image
    interface = "ide2"
  }

  cpu {
    cores      = each.value.hardware.cpu.cores
    flags      = []
    hotplugged = 0
    limit      = 0
    numa       = false
    sockets    = 1
    type       = each.value.hardware.cpu.type
    units      = 1024
  }

  dynamic "disk" {
    for_each = each.value.hardware.disks
    content {
      aio          = "io_uring"
      backup       = false
      cache        = "none"
      datastore_id = disk.value.datastore_id
      discard      = "on"
      file_format  = "raw"
      interface    = disk.value.interface
      iothread     = true
      replicate    = true
      serial       = disk.value.serial
      size         = disk.value.size
      ssd          = false
    }
  }

  memory {
    dedicated      = each.value.hardware.memory
    floating       = each.value.hardware.memory
    keep_hugepages = false
    shared         = 0
  }

  dynamic "network_device" {
    for_each = each.value.hardware.network_devices
    content {
      bridge       = network_device.value.interface
      disconnected = network_device.value.disconnected
      enabled      = true
      firewall     = false
      model        = "virtio"
      mac_address  = network_device.value.mac_address
      mtu          = 0
      queues       = 0
      rate_limit   = 0
      vlan_id      = network_device.value.vlan_id
    }
  }

  on_boot = false

  startup {
    order = 1
  }

  vga {
    memory = each.value.hardware.vga.memory
    type   = each.value.hardware.vga.type
  }

  operating_system {
    type = "l26"
  }

  reboot              = false
  reboot_after_update = false
  serial_device {}

  tpm_state {
    datastore_id = "local-lvm"
    version      = "v2.0"
  }
}
