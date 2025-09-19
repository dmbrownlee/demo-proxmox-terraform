terraform {
  required_version = "~> 1.9.1"
  required_providers {
    ansible = {
      source  = "ansible/ansible"
      version = "~> 1.3.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5.3"
    }
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.83.2"
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
