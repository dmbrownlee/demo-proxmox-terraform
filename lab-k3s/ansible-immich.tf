variable "want_k3s_photos" {
  type    = bool
  default = false
}

resource "ansible_playbook" "k3s_photos" {
  count                   = var.want_k3s_photos ? 1 : 0
  playbook                = "ansible/playbook-immich.yml"
  name                    = "localhost"
  replayable              = var.ansible_replayable
  ignore_playbook_failure = true
  extra_vars = {
    ansible_hostname          = "localhost"
    ansible_connection        = "local"
    private_key               = var.ssh_private_key_files[var.ci_user]
    ansible_ssh_user          = var.ci_user
    k3s_local_kubeconfig_path = var.k3s_local_kubeconfig_path
  }
  depends_on = [
    resource.ansible_playbook.k3s_longhorn,
    resource.ansible_playbook.k3s_prometheus,
  ]
}

output "playbook_output_k3s_photos" {
  value = var.want_ansible_output && var.want_k3s_photos ? ansible_playbook.k3s_photos : null
}
