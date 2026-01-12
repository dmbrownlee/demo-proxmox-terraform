###############################################################################
###############################################################################
##
##  Variable Definitions
##
###############################################################################
###############################################################################
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
    role             = string,
    pve_node         = string,
    cloud_init_image = string,
    ipv4_address     = string,
    on_boot          = bool,
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
      initialization = object({
        datastore_id = string,
      })
      memory = number
      network_devices = list(object({
        interface   = string,
        mac_address = string,
        vlan_id     = number,
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
resource "proxmox_virtual_environment_vm" "k3s_initial_cp" {
  depends_on = [
    resource.dns_a_record_set.k3s_initial_cp,
    data.proxmox_virtual_environment_vms.cloud_init_template,
  ]
  for_each    = { for vm in var.vms : vm.hostname => vm if vm.role == "k3s_initial_cp" }
  name        = each.key
  description = "Managed by Terraform"
  tags        = ["${terraform.workspace}", each.value.cloud_init_image]
  node_name   = each.value.pve_node
  vm_id       = each.value.vm_id
  started     = true

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
    datastore_id = each.value.hardware.initialization.datastore_id
    dns {
      servers = var.vlans[index(var.vlans.*.vlan_id, each.value.hardware.network_devices[0].vlan_id)].ipv4_dns_servers
      domain  = var.site_domain
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
  on_boot = each.value.on_boot
  connection {
    type  = "ssh"
    user  = var.ci_user
    agent = true
    host  = "${self.name}.${var.site_domain}"
  }
  provisioner "local-exec" {
    command = "sleep ${var.sleep_seconds_before_remote_provisioning}"
  }
  provisioner "remote-exec" {
    inline = ["hostnamectl"]
  }
  startup {
    down_delay = -1
    order      = 1
    up_delay   = -1
  }
  vga {
    type = "qxl"
  }
}

resource "proxmox_virtual_environment_haresource" "k3s_initial_cp" {
  depends_on = [
    resource.proxmox_virtual_environment_vm.k3s_initial_cp
  ]
  for_each    = { for vm in var.vms : vm.hostname => vm if vm.role == "k3s_initial_cp" }
  resource_id = "vm:${each.value.vm_id}"
  state       = "started"
}

resource "proxmox_virtual_environment_vm" "k3s_servers" {
  depends_on = [
    resource.dns_a_record_set.k3s_servers,
    data.proxmox_virtual_environment_vms.cloud_init_template,
  ]
  for_each    = { for vm in var.vms : vm.hostname => vm if var.want_k3s_servers && vm.role == "k3s_server" }
  name        = each.key
  description = "Managed by Terraform"
  tags        = ["${terraform.workspace}", each.value.cloud_init_image]
  node_name   = each.value.pve_node
  vm_id       = each.value.vm_id
  started     = true

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
    datastore_id = each.value.hardware.initialization.datastore_id
    dns {
      servers = var.vlans[index(var.vlans.*.vlan_id, each.value.hardware.network_devices[0].vlan_id)].ipv4_dns_servers
      domain  = var.site_domain
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
  on_boot = each.value.on_boot
  connection {
    type  = "ssh"
    user  = var.ci_user
    agent = true
    host  = "${self.name}.${var.site_domain}"
  }
  provisioner "local-exec" {
    command = "sleep ${var.sleep_seconds_before_remote_provisioning}"
  }
  provisioner "remote-exec" {
    inline = ["hostnamectl"]
  }
  startup {
    down_delay = -1
    order      = 10
    up_delay   = 30
  }
  vga {
    type = "qxl"
  }
}

resource "proxmox_virtual_environment_haresource" "k3s_servers" {
  depends_on = [
    resource.proxmox_virtual_environment_vm.k3s_servers
  ]
  for_each    = { for vm in var.vms : vm.hostname => vm if vm.role == "k3s_server" }
  resource_id = "vm:${each.value.vm_id}"
  state       = "started"
}

resource "proxmox_virtual_environment_vm" "k3s_agents" {
  depends_on = [
    resource.dns_a_record_set.k3s_agents,
    data.proxmox_virtual_environment_vms.cloud_init_template,
  ]
  for_each    = { for vm in var.vms : vm.hostname => vm if var.want_k3s_agents && vm.role == "k3s_agent" }
  name        = each.key
  description = "Managed by Terraform"
  tags        = ["${terraform.workspace}", each.value.cloud_init_image]
  node_name   = each.value.pve_node
  vm_id       = each.value.vm_id
  started     = true

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
    datastore_id = each.value.hardware.initialization.datastore_id
    dns {
      servers = var.vlans[index(var.vlans.*.vlan_id, each.value.hardware.network_devices[0].vlan_id)].ipv4_dns_servers
      domain  = var.site_domain
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
  on_boot = each.value.on_boot
  connection {
    type  = "ssh"
    user  = var.ci_user
    agent = true
    host  = "${self.name}.${var.site_domain}"
  }
  provisioner "local-exec" {
    command = "sleep ${var.sleep_seconds_before_remote_provisioning}"
  }
  provisioner "remote-exec" {
    inline = ["hostnamectl"]
  }
  startup {
    down_delay = -1
    order      = 20
    up_delay   = 60
  }
  vga {
    type = "qxl"
  }
}

resource "proxmox_virtual_environment_haresource" "k3s_agents" {
  depends_on = [
    resource.proxmox_virtual_environment_vm.k3s_agents
  ]
  for_each    = { for vm in var.vms : vm.hostname => vm if vm.role == "k3s_agent" }
  resource_id = "vm:${each.value.vm_id}"
  state       = "started"
}


resource "proxmox_virtual_environment_vm" "k3s_db_workers" {
  depends_on = [
    resource.dns_a_record_set.k3s_agents,
    data.proxmox_virtual_environment_vms.cloud_init_template,
  ]
  for_each    = { for vm in var.vms : vm.hostname => vm if var.want_k3s_db_workers && vm.role == "k3s_db_worker" }
  name        = each.key
  description = "Managed by Terraform"
  tags        = ["${terraform.workspace}", each.value.cloud_init_image]
  node_name   = each.value.pve_node
  vm_id       = each.value.vm_id
  started     = true

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
    datastore_id = each.value.hardware.initialization.datastore_id
    dns {
      servers = var.vlans[index(var.vlans.*.vlan_id, each.value.hardware.network_devices[0].vlan_id)].ipv4_dns_servers
      domain  = var.site_domain
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
  on_boot = each.value.on_boot
  connection {
    type  = "ssh"
    user  = var.ci_user
    agent = true
    host  = "${self.name}.${var.site_domain}"
  }
  provisioner "local-exec" {
    command = "sleep ${var.sleep_seconds_before_remote_provisioning}"
  }
  provisioner "remote-exec" {
    inline = ["hostnamectl"]
  }
  startup {
    order = 20
  }
  vga {
    type = "qxl"
  }
}

