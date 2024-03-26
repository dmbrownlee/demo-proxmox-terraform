output "playbook_output_k8s_workers" {
  value = var.want_k8s ? ansible_playbook.k8s_workers : null
}
