terraform {
  required_version = "~> 1.8.1"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.65.0"
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
