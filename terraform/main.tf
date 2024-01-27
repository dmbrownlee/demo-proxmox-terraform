terraform {
  required_version = ">= 1.7.1"
  required_providers {
    proxmox = {
      source  = "TheGameProfi/proxmox"
      version = "2.9.15"
    }
    ansible = {
      source  = "ansible/ansible"
      version = "1.1.0"
    }
  }
}
