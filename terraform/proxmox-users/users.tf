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
  user_id = var.terraform_proxmox_account
}
