output "playbook_output_yunohost" {
  value = var.want_yunohost ? ansible_playbook.yunohost : null
}
