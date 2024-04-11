terraform {
  required_version = "~> 1.7.5"
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "2.5.1"
    }
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
