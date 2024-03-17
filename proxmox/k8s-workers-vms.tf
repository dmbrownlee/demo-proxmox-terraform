resource "proxmox_virtual_environment_vm" "k8s_workers" {
  depends_on = [
    proxmox_virtual_environment_vm.vm_templates,
    proxmox_virtual_environment_vm.dnsmasq
  ]
  for_each    = { for vm in var.vms : vm.hostname => vm if vm.role == "k8s_worker" }
  name        = each.key
  description = "Managed by Terraform"
  tags        = ["terraform", each.value.cloud_init_image, each.value.role]
  node_name   = each.value.pve_node
  vm_id       = each.value.vm_id

  clone {
    datastore_id = var.vm_template_storage.name
    node_name    = var.vm_template_storage.node
    vm_id        = var.vm_templates[each.value.cloud_init_image].vm_id
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
    }
    ip_config {
      ipv4 {
        address = each.value.ipv4_address
        gateway = var.vlans[index(var.vlans.*.vlan_id, each.value.vlan_id)].ipv4_gateway
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
