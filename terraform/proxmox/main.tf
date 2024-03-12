terraform {
  required_version = "~> 1.7.4"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.48.0"
    }
    ansible = {
      source  = "ansible/ansible"
      version = "1.2.0"
    }
  }
}

provider "proxmox" {
  api_token = var.api_token
  endpoint  = var.endpoint
  insecure  = true
  ssh {
    agent    = true
    username = "root"
  }
}
