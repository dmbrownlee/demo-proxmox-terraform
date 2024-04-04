output "playbook_output_k3s_initial_cp" {
  value = var.want_k3s_master ? ansible_playbook.k3s_master : null
}

output "playbook_output_k3s_cp" {
  value = var.want_k3s_servers ? ansible_playbook.k3s_servers : null
}

output "playbook_output_k3s_workers" {
  value = var.want_k3s_agents ? ansible_playbook.k3s_agents : null
}

