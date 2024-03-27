variable "k3s_version" {
  description = "Version of K3S to install"
  type        = string
  default     = "v1.29.2+k3s1"
}

variable "k3s_token" {
  description = "Join token for K3S"
  type        = string
}

resource "ansible_host" "k3s_initial_cp" {
  for_each = { for vm in var.vms : vm.hostname => vm if var.want_k3s && vm.role == "k3s_initial_cp" }
  name     = each.key
  groups   = ["k3s_initial_cp"]
  depends_on = [
    resource.proxmox_virtual_environment_vm.k3s
  ]
}

resource "ansible_group" "k3s_initial_cp" {
  name     = "k3s_initial_cp"
  children = [for vm in var.vms : vm.hostname if var.want_k3s && vm.role == "k3s_initial_cp"]
  depends_on = [
    resource.proxmox_virtual_environment_vm.k3s
  ]
}

resource "ansible_playbook" "k3s_initial_cp" {
  for_each                = { for vm in var.vms : vm.hostname => vm if var.want_k3s && vm.role == "k3s_initial_cp" }
  playbook                = "ansible/k3s/playbook.yml"
  name                    = each.key
  replayable              = var.ansible_replayable
  groups                  = ["k3s_initial_cp"]
  ignore_playbook_failure = true
  extra_vars = {
    private_key      = var.ssh_private_key_files[var.ci_user]
    ansible_ssh_user = var.ci_user
    k3s_token        = var.k3s_token
    k3s_version      = var.k3s_version
  }
  depends_on = [
    resource.ansible_host.k3s_initial_cp,
  ]
}

resource "ansible_host" "k3s_cp" {
  for_each = { for vm in var.vms : vm.hostname => vm if var.want_k3s && vm.role == "k3s_cp" }
  name     = each.key
  groups   = ["k3s_cp"]
  depends_on = [
    resource.proxmox_virtual_environment_vm.k3s
  ]
}

resource "ansible_group" "k3s_cp" {
  name     = "k3s_cp"
  children = [for vm in var.vms : vm.hostname if var.want_k3s && vm.role == "k3s_cp"]
  depends_on = [
    resource.proxmox_virtual_environment_vm.k3s
  ]
}

resource "ansible_playbook" "k3s_cp" {
  for_each                = { for vm in var.vms : vm.hostname => vm if var.want_k3s && vm.role == "k3s_cp" }
  playbook                = "ansible/k3s/playbook.yml"
  name                    = each.key
  replayable              = var.ansible_replayable
  groups                  = ["k3s_cp"]
  ignore_playbook_failure = true
  extra_vars = {
    private_key      = var.ssh_private_key_files[var.ci_user]
    ansible_ssh_user = var.ci_user
    k3s_token        = var.k3s_token
    k3s_version      = var.k3s_version
  }
  depends_on = [
    resource.ansible_host.k3s_cp,
    resource.ansible_playbook.k3s_initial_cp,
  ]
}

resource "ansible_host" "k3s_workers" {
  for_each = { for vm in var.vms : vm.hostname => vm if var.want_k3s && vm.role == "k3s_worker" }
  name     = each.key
  groups   = ["k3s_worker"]
  depends_on = [
    resource.proxmox_virtual_environment_vm.k3s
  ]
}

resource "ansible_group" "k3s_workers" {
  name     = "k3s_workers"
  children = [for vm in var.vms : vm.hostname if var.want_k3s && vm.role == "k3s_worker"]
  depends_on = [
    resource.proxmox_virtual_environment_vm.k3s
  ]
}

resource "ansible_playbook" "k3s_workers" {
  for_each                = { for vm in var.vms : vm.hostname => vm if var.want_k3s && vm.role == "k3s_worker" }
  playbook                = "ansible/k3s/playbook.yml"
  name                    = each.key
  replayable              = var.ansible_replayable
  groups                  = ["k3s_workers"]
  ignore_playbook_failure = true
  extra_vars = {
    private_key      = var.ssh_private_key_files[var.ci_user]
    ansible_ssh_user = var.ci_user
    k3s_token        = var.k3s_token
    k3s_version      = var.k3s_version
  }
  depends_on = [
    resource.ansible_host.k3s_workers,
    resource.ansible_playbook.k3s_cp,
  ]
}
