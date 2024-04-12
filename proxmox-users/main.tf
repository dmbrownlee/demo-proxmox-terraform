terraform {
  required_version = "~> 1.7.5"
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "2.5.1"
    }
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.53.1"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.0.5"
    }
  }
}

provider "proxmox" {
  endpoint = var.endpoint
  username = var.rootaccount
  password = var.rootpassword
  insecure = true
  ssh {
    agent = true
  }
}
