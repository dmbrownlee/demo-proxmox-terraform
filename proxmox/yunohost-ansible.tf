resource "ansible_host" "yunohost" {
  for_each = { for vm in var.vms : vm.hostname => vm if var.want_yunohost && vm.role == "yunohost" }
  name     = each.key
  groups   = ["yunohost"]
  depends_on = [
    resource.proxmox_virtual_environment_vm.yunohost
  ]
}

resource "ansible_playbook" "yunohost" {
  for_each                = { for vm in var.vms : vm.hostname => vm if var.want_yunohost && vm.role == "yunohost" }
  playbook                = "ansible/yunohost/playbook.yml"
  name                    = each.key
  replayable              = var.ansible_replayable
  ignore_playbook_failure = true
  extra_vars = {
    private_key      = var.ssh_private_key_files[var.ci_user]
    ansible_ssh_user = var.ci_user
  }
  depends_on = [
    resource.ansible_host.yunohost,
  ]
}

output "playbook_output_yunohost" {
  value = var.want_ansible_output && var.want_yunohost ? ansible_playbook.yunohost : null
}
