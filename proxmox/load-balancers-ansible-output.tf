output "playbook_output_load_balancers" {
  value = var.want_k8s ? ansible_playbook.load_balancers : null
}
