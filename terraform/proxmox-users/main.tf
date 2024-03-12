terraform {
  required_version = "~> 1.7.4"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.48.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.0.5"
    }
  }
}

#-- Providers --------------------------------------
provider "proxmox" {
  endpoint  = var.endpoint
  username  = var.rootaccount
  password  = var.rootpassword
  insecure  = true
  ssh {
    agent = true
  }
}

#-- Variables --------------------------------------
variable "endpoint" {
  description = "URL of the Proxmox cluster API"
  type        = string
}

variable "rootaccount" {
  description = "Default Proxmox administration account"
  type        = string
  default     = "root@pam"
}

variable "rootpassword" {
  description = "Password for default Proxmox administration account"
  type        = string
  sensitive   = true
}

variable "tfaccount" {
  description = "Terraform administration account"
  type        = string
  default     = "terraform@pve"
}

#-- Resources --------------------------------------
resource "proxmox_virtual_environment_role" "role_terraform" {
  role_id = "TERRAFORM"

  privileges = [
    "Datastore.Allocate",
    "Datastore.AllocateSpace",
    "Datastore.AllocateTemplate",
    "Datastore.Audit",
    "Mapping.Audit",
    "Pool.Allocate",
    "Pool.Audit",
    "SDN.Audit",
    "Sys.Audit",
    "Sys.Console",
    "Sys.Modify",
    "VM.Allocate",
    "VM.Audit",
    "VM.Clone",
    "VM.Config.CDROM",
    "VM.Config.Cloudinit",
    "VM.Config.CPU",
    "VM.Config.Disk",
    "VM.Config.HWType",
    "VM.Config.Memory",
    "VM.Config.Network",
    "VM.Config.Options",
    "VM.Console",
    "VM.Migrate",
    "VM.Monitor",
    "VM.PowerMgmt",
    "SDN.Use"
  ]
}

resource "proxmox_virtual_environment_user" "user_terraform" {
  acl {
    path      = "/"
    propagate = true
    role_id   = proxmox_virtual_environment_role.role_terraform.role_id
  }
  enabled = true
  groups  = []
  user_id = var.tfaccount
}
