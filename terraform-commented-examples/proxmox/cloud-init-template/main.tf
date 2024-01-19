terraform {
  required_version = "~> 1.6.1"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.43.2"
    }
  }
}

#-- Providers --------------------------------------
provider "proxmox" {
  endpoint = var.endpoint
  api_token = var.api_token
  username = var.tfaccount
  insecure = true
  ssh {
    agent = true
    username = "root"
  }
}

#-- Variables --------------------------------------
variable "endpoint" {
  description = "URL of the Proxmox cluster API"
  type        = string
}

variable "api_token" {
  description = "Proxmox API token"
  type        = string
}

variable "tfaccount" {
  description = "Terraform administration account"
  type        = string
  default     = "terraform@pve"
}

#-- Resources --------------------------------------
resource "proxmox_virtual_environment_download_file" "latest_debian_12_genericcloud_qcow2_img" {
    content_type = "iso"
    datastore_id = "truenas1"
    file_name    = "debian-12-genericcloud-amd64.qcow2.img"
    node_name    = "pve3"
    url          = "https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2"
}

resource "proxmox_virtual_environment_vm" "debian12_genericcloud_template" {
    acpi                    = true
    bios                    = "seabios"
    keyboard_layout         = "en-us"
    migrate                 = false
    name                    = "debian12-genericcloud"
    node_name               = "pve3"
    on_boot                 = false
    reboot                  = false
    scsi_hardware           = "virtio-scsi-single"
    started                 = false
    tablet_device           = true
    tags                    = [
        "debian12-genericcloud",
        "terraform"
    ]
    template                = true
    timeout_clone           = 1800
    timeout_create          = 1800
    timeout_migrate         = 1800
    timeout_move_disk       = 1800
    timeout_reboot          = 1800
    timeout_shutdown_vm     = 1800
    timeout_start_vm        = 1800
    timeout_stop_vm         = 300
    vm_id                   = "999"

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
        datastore_id = "truenas1"
        discard      = "on"
        file_id      = proxmox_virtual_environment_download_file.latest_debian_12_genericcloud_qcow2_img.id
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
        bridge      = "vmbr0"
        enabled     = true
        firewall    = true
        #mac_address = "BC:24:11:58:1B:C7"
        model       = "virtio"
        mtu         = 0
        queues      = 0
        rate_limit  = 0
        #vlan_id     = 1000
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
