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

variable "admin_laptop" {
  description = "A single VM object"
  type = object({
    vm_id            = number,
    hostname         = string,
    domain           = string,
    pve_node         = string,
    cloud_init_image = string,
    ipv4_address     = string,
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
      memory = number
      network_devices = list(object({
        interface   = string,
        mac_address = string,
        vlan_id     = number,
      }))
    })
  })
}

variable "bios_hosts" {
  description = "A single VM object"
  type = list(object({
    vm_id            = number,
    hostname         = string,
    pve_node         = string,
  }))
}

variable "uefi_hosts" {
  description = "A single VM object"
  type = list(object({
    vm_id            = number,
    hostname         = string,
    pve_node         = string,
  }))
}

###############################################################################
###############################################################################
##
##  Resource Definitions
##
###############################################################################
###############################################################################
resource "dns_a_record_set" "admin_laptop" {
  zone      = "${var.admin_laptop.dns.zone}."
  name      = var.admin_laptop.hostname
  addresses = ["${var.admin_laptop.dns.rr_a}"]
  ttl       = 300
}

# resource "dns_ptr_record" "admin_laptop" {
#   zone = "${var.bootstrap_mgmt_dns.reverse_zone}."
#   name = var.bootstrap_mgmt_dns.ptr_rr
#   ptr  = "${var.bootstrap_mgmt_dns.hostname}.${var.bootstrap_mgmt_dns.zone}."
#   ttl  = 300
# }

resource "proxmox_virtual_environment_vm" "admin_laptop" {
  depends_on = [
    resource.dns_a_record_set.admin_laptop,
    data.proxmox_virtual_environment_vms.cloud_init_template,
  ]
  name        = "${var.admin_laptop.hostname}"
  description = "Managed by Terraform"
  tags        = ["${terraform.workspace}", var.admin_laptop.cloud_init_image]
  node_name   = var.admin_laptop.pve_node
  vm_id       = var.admin_laptop.vm_id

  clone {
    datastore_id = var.vm_template_storage.name
    node_name    = var.vm_template_storage.node
    vm_id        = data.proxmox_virtual_environment_vms.cloud_init_template.vms[index(data.proxmox_virtual_environment_vms.cloud_init_template.vms[*].name, var.admin_laptop.cloud_init_image)].vm_id
    full         = true
  }
  cpu {
    sockets = 1
    cores   = var.admin_laptop.hardware.cpu.cores
    type    = var.admin_laptop.hardware.cpu.type
  }
  dynamic "disk" {
    for_each = var.admin_laptop.hardware.disks
    content {
      datastore_id = disk.value.datastore_id
      interface    = disk.value.interface
      size         = disk.value.size
      discard      = "on"
      file_format  = "raw"
      iothread     = true
      ssd          = true
    }
  }
  initialization {
    #datastore_id = var.vm_storage
    datastore_id = "local-lvm"
    dns {
      servers = var.vlans[index(var.vlans.*.vlan_id, var.admin_laptop.hardware.network_devices[0].vlan_id)].ipv4_dns_servers
      domain  = var.admin_laptop.domain
    }
    ip_config {
      ipv4 {
        address = var.admin_laptop.ipv4_address
        gateway = var.vlans[index(var.vlans.*.vlan_id, var.admin_laptop.hardware.network_devices[0].vlan_id)].ipv4_gateway
      }
    }
    user_account {
      username = var.ci_user
      password = var.ci_password
      keys     = [trimspace(data.local_file.ci_ssh_public_key_file.content)]
    }
  }
  memory {
    dedicated = var.admin_laptop.hardware.memory
    floating  = var.admin_laptop.hardware.memory
  }
  dynamic "network_device" {
    for_each = var.admin_laptop.hardware.network_devices
    content {
      bridge      = network_device.value.interface
      mac_address = network_device.value.mac_address
      vlan_id     = network_device.value.vlan_id
    }
  }
  on_boot = true
  connection {
    type  = "ssh"
    user  = var.ci_user
    agent = true
    host  = "${self.name}.${var.admin_laptop.domain}"
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
    memory = 512
    type = "std"
  }
}


resource "ansible_host" "admin_laptop" {
  name     = var.admin_laptop.hostname
  groups   = ["admin_laptop"]
  depends_on = [
    resource.proxmox_virtual_environment_vm.admin_laptop
  ]
}

resource "proxmox_virtual_environment_vm" "uefihosts" {
  lifecycle {
    ignore_changes = [mac_addresses]
  }
    for_each    = { for vm in var.uefi_hosts : vm.hostname => vm }
    acpi                    = true
    bios                    = "ovmf"
    boot_order              = ["scsi0","net0","ide2"]
    mac_addresses           = []
    machine                 = "q35"
    name                    = each.key
    node_name               = each.value.pve_node
    protection              = false
    scsi_hardware           = "virtio-scsi-single"
    started                 = false
    tablet_device           = true
    tags                    = []
    template                = false
    vm_id                   = each.value.vm_id

    cpu {
        cores      = 2
        flags      = []
        hotplugged = 0
        limit      = 0
        numa       = false
        sockets    = 1
        type       = "x86-64-v2-AES"
        units      = 1024
    }

    cdrom {
        file_id           = "none"
        interface         = "ide2"
    }

    disk {
        aio               = "io_uring"
        backup            = false
        cache             = "none"
        datastore_id      = "local-lvm"
        discard           = "on"
        file_format       = "raw"
        interface         = "scsi0"
        iothread          = true
        # path_in_datastore = "vm-204-disk-1"
        replicate         = true
        size              = 32
        ssd               = true
    }

    # efi_disk {
    #     datastore_id      = "local-lvm"
    #     file_format       = "raw"
    #     #pre_enrolled_keys = false
    #     type              = "4m"
    # }

    memory {
        dedicated      = 8192
        floating       = 0
        keep_hugepages = false
        shared         = 0
    }

    network_device {
        bridge       = "vmbr1"
        disconnected = false
        enabled      = true
        firewall     = false
        model        = "virtio"
        mtu          = 0
        queues       = 0
        rate_limit   = 0
        vlan_id      = 0
    }

    network_device {
        bridge       = "vmbr1"
        disconnected = true
        enabled      = true
        firewall     = false
        model        = "virtio"
        mtu          = 0
        queues       = 0
        rate_limit   = 0
        vlan_id      = 0
    }

    on_boot                 = false

    operating_system {
        type = "l26"
    }

    reboot                  = false
    reboot_after_update     = false
    serial_device {}

    tpm_state {
        datastore_id      = "local-lvm"
        version           = "v2.0"
    }

    vga {
      type = "qxl"
    }
}

resource "proxmox_virtual_environment_vm" "bioshosts" {
  lifecycle {
    ignore_changes = [mac_addresses]
  }
    for_each    = { for vm in var.bios_hosts : vm.hostname => vm }
    acpi                    = true
    bios                    = "seabios"
    mac_addresses           = []
    machine                 = "q35"
    name                    = each.key
    node_name               = each.value.pve_node
    protection              = false
    scsi_hardware           = "virtio-scsi-single"
    started                 = false
    tablet_device           = true
    tags                    = []
    template                = false
    vm_id                   = each.value.vm_id

    cpu {
        cores      = 2
        flags      = []
        hotplugged = 0
        limit      = 0
        numa       = false
        sockets    = 1
        type       = "x86-64-v2-AES"
        units      = 1024
    }

    disk {
        aio               = "io_uring"
        backup            = false
        cache             = "none"
        datastore_id      = "local-lvm"
        discard           = "on"
        file_format       = "raw"
        interface         = "scsi0"
        iothread          = true
        #path_in_datastore = "vm-205-disk-0"
        replicate         = true
        size              = 32
        ssd               = true
    }

    memory {
        dedicated      = 8192
        floating       = 0
        keep_hugepages = false
        shared         = 0
    }

    network_device {
        bridge       = "vmbr1"
        disconnected = false
        enabled      = true
        firewall     = false
        model        = "virtio"
        mtu          = 0
        queues       = 0
        rate_limit   = 0
        vlan_id      = 0
    }

    network_device {
        bridge       = "vmbr0"
        disconnected = true
        enabled      = true
        firewall     = false
        model        = "virtio"
        mtu          = 0
        queues       = 0
        rate_limit   = 0
        vlan_id      = 0
    }

    operating_system {
        type = "l26"
    }
}
