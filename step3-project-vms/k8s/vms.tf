###############################################################################
###############################################################################
##
##  Variables
##
###############################################################################
###############################################################################
# dns_domainname is used in two places.  First, it is used as the DNS domain
# when creating the cloud-init drive for VMs.  Second, it is used as the
# FQDN's suffix when connecting via SSH.
variable "dns_domainname" {
  description = "The DNS domain for all VMs"
  type        = string
  default     = "example.com"
}

# Proxmox will return the VM has booted even though the OS is still starting.
# This is the number of seconds to wait after Proxmox says the VM has started
# before attempting to verify that SSH is working.  If your Proxmox VMs are
# slow, you can reduce the number of failed attempts by increasing this delay.
variable "sleep_seconds_before_testing_connectivity" {
  description = "The number of seconds to wait before testing SSH"
  type        = number
}


###############################################################################
###############################################################################
##
##  Resources
##
###############################################################################
###############################################################################
resource "proxmox_virtual_environment_vm" "k8s_control_plane_nodes" {
  depends_on = [
    data.proxmox_virtual_environment_vms.cloud_init_template
  ]
  for_each    = { for vm in var.vms : vm.hostname => vm if vm.role == "k8s_first_control_plane_node" || vm.role == "k8s_control_plane_node" }
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
    cores   = each.value.hardware.cpu_cores
    type    = "x86-64-v2-AES"
  }
  disk {
    datastore_id = var.vm_storage
    interface    = "scsi0"
    size         = each.value.hardware.disk
    discard      = "on"
    iothread     = true
    ssd          = true
  }
  initialization {
    datastore_id = var.vm_storage
    dns {
      servers = var.vlans[index(var.vlans.*.vlan_id, each.value.vlan_id)].ipv4_dns_servers
      domain  = var.dns_domainname
    }
    ip_config {
      ipv4 {
        address = each.value.ipv4_address
        gateway = var.vlans[index(var.vlans.*.vlan_id, each.value.vlan_id)].ipv4_gateway
      }
    }
    #upgrade = false
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
    host  = "${self.name}.${var.dns_domainname}"
  }
  provisioner "local-exec" {
    command = "sleep ${var.sleep_seconds_before_testing_connectivity}"
  }
  provisioner "remote-exec" {
    inline = ["hostnamectl"]
  }
  startup {
    order = 10
  }
  vga {
    type = "qxl"
  }
}

resource "proxmox_virtual_environment_vm" "k8s_worker_nodes" {
  depends_on = [
    data.proxmox_virtual_environment_vms.cloud_init_template
  ]
  for_each    = { for vm in var.vms : vm.hostname => vm if vm.role == "k8s_worker_node" }
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
    cores   = each.value.hardware.cpu_cores
    type    = "x86-64-v2-AES"
  }
  disk {
    datastore_id = var.vm_storage
    interface    = "scsi0"
    size         = each.value.hardware.disk
    discard      = "on"
    iothread     = true
    ssd          = true
  }
  initialization {
    datastore_id = var.vm_storage
    dns {
      servers = var.vlans[index(var.vlans.*.vlan_id, each.value.vlan_id)].ipv4_dns_servers
      domain  = var.dns_domainname
    }
    ip_config {
      ipv4 {
        address = each.value.ipv4_address
        gateway = var.vlans[index(var.vlans.*.vlan_id, each.value.vlan_id)].ipv4_gateway
      }
    }
    #upgrade = false
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
    host  = "${self.name}.${var.dns_domainname}"
  }
  provisioner "local-exec" {
    command = "sleep ${var.sleep_seconds_before_testing_connectivity}"
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
