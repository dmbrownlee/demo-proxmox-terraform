##############################################################################
##
##  Variable definitions
##
##############################################################################
variable "terraform_proxmox_role" {
  description = "The name of the Proxmox role Terraform will use (determines ACLs)"
  type        = string
  default     = "TERRAFORM"
}

variable "terraform_proxmox_account" {
  description = "Terraform administration account"
  type        = string
  default     = "terraform@pve"
}

##############################################################################
##
##  Resources
##
##############################################################################
resource "proxmox_virtual_environment_role" "role_terraform" {
  role_id = var.terraform_proxmox_role

  privileges = [
    "Datastore.Allocate",
    "Datastore.AllocateSpace",
    "Datastore.AllocateTemplate",
    "Datastore.Audit",
    "Mapping.Audit",
    "Mapping.Modify",
    "Mapping.Use",
    "Pool.Allocate",
    "Pool.Audit",
    "SDN.Allocate",
    "SDN.Audit",
    "SDN.Use",
    "Sys.Audit",
    "Sys.Console",
    "Sys.Modify",
    "Sys.PowerMgmt",
    "VM.Allocate",
    "VM.Audit",
    "VM.Backup",
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
    "VM.GuestAgent.Audit",
    "VM.GuestAgent.FileRead",
    "VM.GuestAgent.FileSystemMgmt",
    "VM.GuestAgent.FileWrite",
    "VM.GuestAgent.Unrestricted",
    "VM.Migrate",
    "VM.PowerMgmt",
    "VM.Replicate",
    "VM.Snapshot",
    "VM.Snapshot.Rollback",
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
  user_id = var.terraform_proxmox_account
}
