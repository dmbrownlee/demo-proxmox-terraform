resource "ansible_host" "dns" {
  for_each = { for vm in var.vms : vm.hostname => vm if vm.role == "dns" }
  name     = each.key
  groups   = ["dns"]
  depends_on = [
    resource.proxmox_virtual_environment_vm.dns
  ]
}

resource "ansible_playbook" "dns" {
  for_each                = { for vm in var.vms : vm.hostname => vm if vm.role == "dns" }
  playbook                = "ansible/playbook.yml"
  name                    = each.key
  replayable              = var.ansible_replayable
  ignore_playbook_failure = true
  extra_vars = {
    private_key      = var.ssh_private_key_files[var.ci_user]
    ansible_ssh_user = var.ci_user
  }
  depends_on = [
    resource.ansible_host.dns
  ]
}

output "playbook_output_dns" {
  value = var.want_ansible_output ? ansible_playbook.dns : null
}

resource "ansible_host" "load_balancers" {
  depends_on = [
    resource.proxmox_virtual_environment_vm.load_balancers
  ]
  for_each = { for vm in var.vms : vm.hostname => vm if vm.role == "load_balancer" }
  name     = each.key
  groups   = ["load_balancers"]
}

resource "ansible_playbook" "load_balancers" {
  depends_on = [
    resource.ansible_host.load_balancers
  ]
  for_each                = { for vm in var.vms : vm.hostname => vm if vm.role == "load_balancer" }
  name                    = each.key
  playbook                = "ansible/playbook-lb.yml"
  replayable              = var.ansible_replayable
  ignore_playbook_failure = true
  var_files = [
    "ansible/files/${each.key}_vrrp.yml"
  ]
  extra_vars = {
    private_key      = var.ssh_private_key_files[var.ci_user]
    ansible_ssh_user = var.ci_user
  }
}

output "playbook_output_load_balancers" {
  value = var.want_ansible_output ? ansible_playbook.load_balancers : null
}
