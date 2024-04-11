resource "ansible_host" "minikube" {
  for_each = { for vm in var.vms : vm.hostname => vm if vm.role == "minikube" }
  name     = each.key
  groups   = ["minikube_nodes"]
  depends_on = [
    resource.proxmox_virtual_environment_vm.minikube
  ]
}

resource "ansible_playbook" "minikube" {
  for_each                = { for vm in var.vms : vm.hostname => vm if vm.role == "minikube" }
  playbook                = "ansible/playbook.yml"
  name                    = each.key
  replayable              = var.ansible_replayable
  ignore_playbook_failure = true
  extra_vars = {
    private_key      = var.ssh_private_key_files[var.ci_user]
    ansible_ssh_user = var.ci_user
  }
  depends_on = [
    resource.ansible_host.minikube
  ]
}

output "playbook_output_minikube" {
  value = var.want_ansible_output ? ansible_playbook.minikube : null
}
