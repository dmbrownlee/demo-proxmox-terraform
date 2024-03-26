output "playbook_output_minikube" {
  value = var.want_minikube ? ansible_playbook.minikube : null
}
