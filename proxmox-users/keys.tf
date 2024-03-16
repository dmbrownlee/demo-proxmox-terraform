resource "tls_private_key" "pveroot_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_sensitive_file" "pveroot_ssh_private_key_file" {
  filename             = pathexpand("${var.ssh_keystore}/${var.pveroot_user}")
  file_permission      = "0600"
  directory_permission = "0700"
  content              = tls_private_key.pveroot_ssh_key.private_key_pem
}

resource "local_file" "pveroot_ssh_public_key_file" {
  filename             = pathexpand("${var.ssh_keystore}/${var.pveroot_user}.pub")
  file_permission      = "0644"
  directory_permission = "0700"
  content              = tls_private_key.pveroot_ssh_key.public_key_openssh
}

resource "tls_private_key" "ci_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_sensitive_file" "ci_ssh_private_key_file" {
  filename             = pathexpand("${var.ssh_keystore}/${var.ci_user}")
  file_permission      = "0600"
  directory_permission = "0700"
  content              = tls_private_key.ci_ssh_key.private_key_pem
}

resource "local_file" "ci_ssh_public_key_file" {
  filename             = pathexpand("${var.ssh_keystore}/${var.ci_user}.pub")
  file_permission      = "0644"
  directory_permission = "0700"
  content              = tls_private_key.ci_ssh_key.public_key_openssh
}

output "ssh_copy_root_key" {
  value = "ssh-copy-id -i ~/keys/pveroot.pub root@pve1"
}

output "ssh_agent_add_root" {
  value = "ssh-add ${local_sensitive_file.pveroot_ssh_private_key_file.filename}"
}

output "ssh_agent_add_ci" {
  value = "ssh-add ${local_sensitive_file.ci_ssh_private_key_file.filename}"
}
