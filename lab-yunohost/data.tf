data "proxmox_virtual_environment_nodes" "available_nodes" {}

data "proxmox_virtual_environment_vms" "cloud_init_template" {
  tags = ["cloud_init_template"]
}

data "local_file" "ci_ssh_public_key_file" {
  filename = pathexpand("${var.ssh_keystore}/${var.ci_user}.pub")
}
