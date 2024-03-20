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
  playbook                = "ansible/dns/playbook.yml"
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
