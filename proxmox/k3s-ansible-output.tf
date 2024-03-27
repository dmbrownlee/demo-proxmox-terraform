output "playbook_output_k3s_initial_cp" {
  value = var.want_k3s ? ansible_playbook.k3s_initial_cp : null
}

output "playbook_output_k3s_cp" {
  value = var.want_k3s ? ansible_playbook.k3s_cp : null
}

output "playbook_output_k3s_workers" {
  value = var.want_k3s ? ansible_playbook.k3s_workers : null
}

