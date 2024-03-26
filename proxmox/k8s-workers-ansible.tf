resource "ansible_host" "k8s_workers" {
  for_each = { for vm in var.vms : vm.hostname => vm if var.want_k8s && vm.role == "k8s_worker" }
  name     = each.key
  groups   = ["worker_nodes"]
  depends_on = [
    resource.proxmox_virtual_environment_vm.k8s_workers
  ]
}

resource "ansible_playbook" "k8s_workers" {
  for_each                = { for vm in var.vms : vm.hostname => vm if var.want_k8s && vm.role == "k8s_worker" }
  playbook                = "ansible/kubernetes/playbook.yml"
  name                    = each.key
  replayable              = var.ansible_replayable
  ignore_playbook_failure = true
  extra_vars = {
    private_key      = var.ssh_private_key_files[var.ci_user]
    ansible_ssh_user = var.ci_user
  }
  depends_on = [
    resource.ansible_host.k8s_workers,
    resource.ansible_playbook.k8s_control_plane
  ]
}
