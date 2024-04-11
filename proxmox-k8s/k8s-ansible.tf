resource "ansible_host" "k8s_servers" {
  for_each = { for vm in var.vms : vm.hostname => vm if vm.role == "k8s_server" }
  name     = each.key
  groups   = ["k8s_servers"]
  depends_on = [
    resource.proxmox_virtual_environment_vm.k8s_servers
  ]
}

resource "ansible_playbook" "k8s_servers" {
  for_each                = { for vm in var.vms : vm.hostname => vm if vm.role == "k8s_server" }
  playbook                = "ansible/playbook.yml"
  name                    = each.key
  replayable              = var.ansible_replayable
  ignore_playbook_failure = true
  extra_vars = {
    private_key      = var.ssh_private_key_files[var.ci_user]
    ansible_ssh_user = var.ci_user
  }
  depends_on = [
    resource.proxmox_virtual_environment_vm.k8s_servers,
    resource.ansible_host.k8s_servers
  ]
}

output "playbook_output_k8s_servers" {
  value = var.want_ansible_output ? ansible_playbook.k8s_servers : null
}

resource "ansible_host" "k8s_agents" {
  for_each = { for vm in var.vms : vm.hostname => vm if vm.role == "k8s_agent" }
  name     = each.key
  groups   = ["agent_nodes"]
  depends_on = [
    resource.proxmox_virtual_environment_vm.k8s_agents
  ]
}

resource "ansible_playbook" "k8s_agents" {
  for_each                = { for vm in var.vms : vm.hostname => vm if vm.role == "k8s_agent" }
  playbook                = "ansible/playbook.yml"
  name                    = each.key
  replayable              = var.ansible_replayable
  ignore_playbook_failure = true
  extra_vars = {
    private_key      = var.ssh_private_key_files[var.ci_user]
    ansible_ssh_user = var.ci_user
  }
  depends_on = [
    resource.proxmox_virtual_environment_vm.k8s_agents,
    resource.ansible_host.k8s_agents,
    resource.ansible_playbook.k8s_servers,
  ]
}

output "playbook_output_k8s_agents" {
  value = var.want_ansible_output ? ansible_playbook.k8s_agents : null
}
