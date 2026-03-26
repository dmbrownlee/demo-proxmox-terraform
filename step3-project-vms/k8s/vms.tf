###############################################################################
###############################################################################
##
##  Variables
##
###############################################################################
###############################################################################
# Proxmox will return the VM has booted even though the OS is still starting.
# This is the number of seconds to wait after Proxmox says the VM has started
# before attempting to verify that SSH is working.  If your Proxmox VMs are
# slow, you can reduce the number of failed attempts by increasing this delay.
variable "sleep_seconds_before_testing_connectivity" {
  description = "The number of seconds to wait before testing SSH"
  type        = number
}

variable "ubuntu_cloud_image" {
  description = "Attribute of the Ubuntu cloud image to use for all VMs"
  type        = object({
    node_name    = string,
    datastore_id = string,
    version      = string,
    release      = string
  })
}

variable "ci_user" {
  description = "Default cloud-init account"
  type        = string
}

variable "ci_password" {
  description = "Password for cloud-init account"
  type        = string
  sensitive   = true
}

variable "ssh_keystore" {
  description = "Local path to directory of SSH keys"
  type        = string
}

variable "vm_storage" {
  description = "Name of Proxmox storage location where VM disks are stored"
  type        = string
  default     = "local-lvm"
}

variable "vms" {
  description = "The list of Proxmox VMs"
  type = list(object({
    vm_id            = number,
    hostname         = string,
    domain           = string,
    role             = string,
    pve_node         = string,
    hardware = object({
      cpu_cores = number,
      memory    = number,
      disk      = number
    })
    mac_address  = string,
    vlan_id      = number,
    ipv4_address = string,
    ipv4_gateway = string,
    ipv4_dns_servers = list(string)
  }))
}


###############################################################################
###############################################################################
##
##  Resources
##
###############################################################################
###############################################################################
data "proxmox_virtual_environment_file" "ubuntu_cloud_image" {
  content_type = "import"
  node_name    = var.ubuntu_cloud_image.node_name
  datastore_id = var.ubuntu_cloud_image.datastore_id
  file_name    = "ubuntu-${var.ubuntu_cloud_image.version}-server-${var.ubuntu_cloud_image.release}.qcow2"
}

resource "proxmox_virtual_environment_vm" "k8s_control_plane_nodes" {
  depends_on = [
    data.proxmox_virtual_environment_vms.cloud_init_template
  ]
  for_each    = { for vm in var.vms : vm.hostname => vm if vm.role == "k8s_first_control_plane_node" || vm.role == "k8s_control_plane_node" }
  name        = each.key
  description = "Managed by Terraform"
  tags        = ["${terraform.workspace}", "ubuntu-${var.ubuntu_cloud_image.version}-server-${var.ubuntu_cloud_image.release}"]
  node_name   = each.value.pve_node
  vm_id       = each.value.vm_id

  cpu {
    sockets = 1
    cores   = each.value.hardware.cpu_cores
    type    = "x86-64-v2-AES"
  }
  disk {
    datastore_id = var.vm_storage
    discard      = "on"
    import_from  = data.proxmox_virtual_environment_file.ubuntu_cloud_image.id
    interface    = "scsi0"
    iothread     = true
    size         = each.value.hardware.disk
    ssd          = true
  }
  initialization {
    datastore_id = var.vm_storage
    dns {
      servers = each.value.ipv4_dns_servers
      domain  = each.value.domain
    }
    ip_config {
      ipv4 {
        address = each.value.ipv4_address
        gateway = each.value.ipv4_gateway
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
    host  = "${self.name}.${each.value.domain}"
  }
  provisioner "local-exec" {
    command = "sleep ${var.sleep_seconds_before_testing_connectivity}"
  }
  provisioner "remote-exec" {
    inline = ["hostnamectl"]
  }
  scsi_hardware = "virtio-scsi-single"
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
  tags        = ["${terraform.workspace}", "ubuntu-${var.ubuntu_cloud_image.version}-server-${var.ubuntu_cloud_image.release}"]
  node_name   = each.value.pve_node
  vm_id       = each.value.vm_id

  cpu {
    sockets = 1
    cores   = each.value.hardware.cpu_cores
    type    = "x86-64-v2-AES"
  }
  disk {
    datastore_id = var.vm_storage
    discard      = "on"
    import_from  = data.proxmox_virtual_environment_file.ubuntu_cloud_image.id
    interface    = "scsi0"
    iothread     = true
    size         = each.value.hardware.disk
    ssd          = true
  }
  initialization {
    datastore_id = var.vm_storage
    dns {
      servers = each.value.ipv4_dns_servers
      domain  = each.value.domain
    }
    ip_config {
      ipv4 {
        address = each.value.ipv4_address
        gateway = each.value.ipv4_gateway
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
    host  = "${self.name}.${each.value.domain}"
  }
  provisioner "local-exec" {
    command = "sleep ${var.sleep_seconds_before_testing_connectivity}"
  }
  provisioner "remote-exec" {
    inline = [
      "echo Waiting for cloud-init to complete on ${each.key}...",
      "cloud-init status --wait > /dev/null",
      "hostnamectl"
    ]
  }
  scsi_hardware = "virtio-scsi-single"
  startup {
    order = 20
  }
  vga {
    type = "qxl"
  }
}
