###############################################################################
###############################################################################
##
##  Variables
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

variable "vlans" {
  description = "Map of VLAN objects indexed on name"
  type = list(object({
    vlan_id          = number,
    comment          = string
    ipv4_gateway     = string,
    ipv4_dns_servers = list(string)
  }))
}

variable "sleep_seconds_before_remote_provisioning" {
  description = "The number of seconds to wait after booting before trying SSH"
  type        = number
}

variable "vm_template_storage" {
  description = "Proxmox node and storage name where VM templates are stored"
  type = object({
    node = string,
    name = string
  })
}

variable "vms" {
  description = "The list of Proxmox VMs"
  type = list(object({
    vm_id            = number,
    hostname         = string,
    domain           = string,
    role             = string,
    pve_node         = string,
    cloud_init_image = string,
    ipv4_address     = string
    hardware = object({
      cpu       = object({
        cores = number,
        type  = string,
      })
      disks     = list(object({
        datastore_id = string,
        interface    = string,
        size         = number
      }))
      memory    = number
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
##  Resources
##
###############################################################################
###############################################################################
resource "proxmox_virtual_environment_vm" "portainer" {
  depends_on = [
    data.proxmox_virtual_environment_vms.cloud_init_template,
  ]
  for_each    = { for vm in var.vms : vm.hostname => vm if vm.role == "portainer" }
  name        = each.key
  description = "Managed by Terraform"
  tags        = ["${terraform.workspace}", each.value.cloud_init_image]
  node_name   = each.value.pve_node
  vm_id       = each.value.vm_id

  clone {
    datastore_id = var.vm_template_storage.name
    node_name    = var.vm_template_storage.node
    vm_id        = data.proxmox_virtual_environment_vms.cloud_init_template.vms[index(data.proxmox_virtual_environment_vms.cloud_init_template.vms[*].name, each.value.cloud_init_image)].vm_id
    full         = true
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
    type = "qxl"
  }
}


resource "ansible_group" "portainer" {
  name = "portainer"
  variables = {
    ansible_ssh_user = var.ci_user
  }
  depends_on = [
    resource.proxmox_virtual_environment_vm.portainer
  ]
}


resource "ansible_host" "portainer" {
  for_each = { for vm in var.vms : vm.hostname => vm if vm.role == "portainer" }
  name     = each.key
  groups   = ["portainer"]
  depends_on = [
    resource.proxmox_virtual_environment_vm.portainer
  ]
}
