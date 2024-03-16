# Currently used by vlans.tf
data "proxmox_virtual_environment_nodes" "available_nodes" {}

data "local_sensitive_file" "ci_ssh_private_key_file" {
  filename = pathexpand("${var.ssh_keystore}/${var.ci_user}")
}

data "local_file" "ci_ssh_public_key_file" {
  filename = pathexpand("${var.ssh_keystore}/${var.ci_user}.pub")
}
