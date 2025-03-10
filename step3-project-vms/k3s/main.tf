# This block specifies the version number of Terraform (I'm actually using
# OpenTofu) and the required provider plugins Terraform will install when
# running 'terraform init' (or 'terraform init -upgrade' when the version
# numbers are updated).  The '~>' notation is like >= except that the actual
# version must have the same major number.
terraform {
  required_version = "~> 1.8.8"
  required_providers {
    ansible = {
      source  = "ansible/ansible"
      version = "~> 1.3.0"
    }
    dns = {
      source  = "hashicorp/dns"
      version = "~> 3.4.2"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5.2"
    }
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.68.0"
    }
  }
}

# This block configures the bpg/proxmox provider.  The variables for endpoint,
# rootaccount, and rootpassword are defined in the variables.tf file.  The
# actual values for these variables is stored in terraform.tfvars which is
# excluded from source control for obvious reasons.  You can copy the example
# terraform.tfvars.example to terraform.tfvars and edit its contents as
# appropriate for your site.
provider "proxmox" {
  # These variables define the URL and authentication credentials to use with
  # Proxmox API.
  api_token = var.api_token
  endpoint  = var.endpoint

  # "insecure" is set to true because I assume your Proxmox cluster is using
  # self-signed certs for TLS.
  insecure = true

  # You must use private key authentication for root access to your Proxmox
  # cluster and the root's private key must be loaded into your locally running
  # SSH agent.  The Proxmox provider tries to use the Proxmox REST API where it
  # can, but some configuration not available in the API must be done via SSH
  # to the cluster with an admin account.  More information on how the
  # bpg/proxmox pluggin does authentication can be found at:
  # https://registry.terraform.io/providers/bpg/proxmox/latest/docs
  ssh {
    agent    = true
    username = "root"
  }
}

provider "dns" {
  update {
    server        = var.dns_server
    key_name      = var.dns_key_name
    key_algorithm = var.dns_key_algorithm
    key_secret    = var.dns_key_secret
  }
}

