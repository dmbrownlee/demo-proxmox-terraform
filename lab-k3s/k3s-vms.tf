resource "proxmox_virtual_environment_vm" "k3s_master" {
  depends_on = [
    proxmox_virtual_environment_network_linux_vlan.vlans,
    data.proxmox_virtual_environment_vms.cloud_init_template
  ]
  for_each    = { for vm in var.vms : vm.hostname => vm if vm.role == "k3s_master" }
  name        = each.key
  description = "Managed by Terraform"
  tags        = ["terraform", each.value.cloud_init_image, each.value.role]
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
    cores   = each.value.hardware.cpu_cores
    type    = "x86-64-v2-AES"
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
      servers = var.vlans[index(var.vlans.*.vlan_id, each.value.vlan_id)].ipv4_dns_servers
      domain  = var.site_domain
    }
    ip_config {
      ipv4 {
        address = each.value.ipv4_address
        gateway = var.vlans[index(var.vlans.*.vlan_id, each.value.vlan_id)].ipv4_gateway
      }
    }
    upgrade = false
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
  network_device {
    bridge      = "vmbr0"
    mac_address = each.value.mac_address
    vlan_id     = each.value.vlan_id
  }
  on_boot = true
  connection {
    type  = "ssh"
    user  = var.ci_user
    agent = true
    host  = self.name
  }
  provisioner "local-exec" {
    command = "sleep ${var.sleep_seconds_before_remote_provisioning}"
  }
  provisioner "remote-exec" {
    inline = ["hostnamectl"]
  }
  vga {
    type = "qxl"
  }
}

resource "proxmox_virtual_environment_vm" "k3s_servers" {
  depends_on = [
    proxmox_virtual_environment_network_linux_vlan.vlans,
    data.proxmox_virtual_environment_vms.cloud_init_template
  ]
  for_each    = { for vm in var.vms : vm.hostname => vm if var.want_k3s_servers && vm.role == "k3s_server" }
  name        = each.key
  description = "Managed by Terraform"
  tags        = ["terraform", each.value.cloud_init_image, each.value.role]
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
    cores   = each.value.hardware.cpu_cores
    type    = "x86-64-v2-AES"
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
      servers = var.vlans[index(var.vlans.*.vlan_id, each.value.vlan_id)].ipv4_dns_servers
      domain  = var.site_domain
    }
    ip_config {
      ipv4 {
        address = each.value.ipv4_address
        gateway = var.vlans[index(var.vlans.*.vlan_id, each.value.vlan_id)].ipv4_gateway
      }
    }
    upgrade = false
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
  network_device {
    bridge      = "vmbr0"
    mac_address = each.value.mac_address
    vlan_id     = each.value.vlan_id
  }
  on_boot = true
  connection {
    type  = "ssh"
    user  = var.ci_user
    agent = true
    host  = self.name
  }
  provisioner "local-exec" {
    command = "sleep ${var.sleep_seconds_before_remote_provisioning}"
  }
  provisioner "remote-exec" {
    inline = ["hostnamectl"]
  }
  vga {
    type = "qxl"
  }
}

resource "proxmox_virtual_environment_vm" "k3s_agents" {
  depends_on = [
    proxmox_virtual_environment_network_linux_vlan.vlans,
    data.proxmox_virtual_environment_vms.cloud_init_template
  ]
  for_each    = { for vm in var.vms : vm.hostname => vm if var.want_k3s_agents && vm.role == "k3s_agent" }
  name        = each.key
  description = "Managed by Terraform"
  tags        = ["terraform", each.value.cloud_init_image, each.value.role]
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
    cores   = each.value.hardware.cpu_cores
    type    = "x86-64-v2-AES"
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
      servers = var.vlans[index(var.vlans.*.vlan_id, each.value.vlan_id)].ipv4_dns_servers
      domain  = var.site_domain
    }
    ip_config {
      ipv4 {
        address = each.value.ipv4_address
        gateway = var.vlans[index(var.vlans.*.vlan_id, each.value.vlan_id)].ipv4_gateway
      }
    }
    upgrade = false
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
  network_device {
    bridge      = "vmbr0"
    mac_address = each.value.mac_address
    vlan_id     = each.value.vlan_id
  }
  on_boot = true
  connection {
    type  = "ssh"
    user  = var.ci_user
    agent = true
    host  = self.name
  }
  provisioner "local-exec" {
    command = "sleep ${var.sleep_seconds_before_remote_provisioning}"
  }
  provisioner "remote-exec" {
    inline = ["hostnamectl"]
  }
  vga {
    type = "qxl"
  }
}

