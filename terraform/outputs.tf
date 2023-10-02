output "id" {
  description = "id"
  value       = proxmox_vm_qemu.vms[*].id
}
output "ip" {
  description = "ipv4"
  value       = proxmox_vm_qemu.vms[*].default_ipv4_address
}
output "ssh_host" {
  description = "ssh host"
  value       = proxmox_vm_qemu.vms[*].ssh_host
}
