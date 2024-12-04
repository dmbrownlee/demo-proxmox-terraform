###############################################################################
###############################################################################
##
##  Variable Definitions
##
###############################################################################
###############################################################################

###############################################################################
###############################################################################
##
##  Ansible config file
##
###############################################################################
###############################################################################
# The Ansible configuration file is required to find Terraform's dynamic
# inventory file.  We only generate the Ansible configuration file dynamically,
# as opposed to checking a static file into source control, because the
# cloud-init user account may be different at your site.
resource "local_file" "ansible_config" {
  filename        = "${path.module}/ansible.cfg"
  file_permission = "0644"
  content         = <<EOF
[defaults]
inventory=.terraform-dynamic-inventory.yml
remote_user=${var.ci_user}
host_key_checking=false
stdout_callback=debug
EOF
}

###############################################################################
###############################################################################
##
##  Dynamic Ansible Inventory Groups
##
###############################################################################
###############################################################################
resource "ansible_group" "k8s_control_plane_nodes" {
  name = "k8s_control_plane_nodes"
  variables = {
    ansible_ssh_user    = var.ci_user
  }
  depends_on = [
    resource.local_file.ansible_config,
    resource.proxmox_virtual_environment_vm.k8s_control_plane_nodes
  ]
}

resource "ansible_group" "k8s_worker_nodes" {
  name = "k8s_worker_nodes"
  variables = {
    ansible_ssh_user    = var.ci_user
  }
  depends_on = [
    resource.local_file.ansible_config,
    resource.proxmox_virtual_environment_vm.k8s_worker_nodes
  ]
}

###############################################################################
###############################################################################
##
##  Dynamic Ansible Inventory Hosts
##
###############################################################################
###############################################################################
resource "ansible_host" "k8s_first_control_plane" {
  for_each = { for vm in var.vms : vm.hostname => vm if vm.role == "k8s_first_control_plane_node" }
  name     = each.key
  groups   = ["k8s_control_plane_nodes", "k8s_first_control_plane"]
  depends_on = [
    resource.local_file.ansible_config,
    resource.proxmox_virtual_environment_vm.k8s_control_plane_nodes
  ]
}

resource "ansible_host" "k8s_additional_control_planes" {
  for_each = { for vm in var.vms : vm.hostname => vm if vm.role == "k8s_control_plane_node" }
  name     = each.key
  groups   = ["k8s_control_plane_nodes", "k8s_additional_control_planes"]
  depends_on = [
    resource.local_file.ansible_config,
    resource.proxmox_virtual_environment_vm.k8s_control_plane_nodes
  ]
}

resource "ansible_host" "k8s_workers" {
  for_each = { for vm in var.vms : vm.hostname => vm if vm.role == "k8s_worker_node" }
  name     = each.key
  groups   = ["k8s_worker_nodes"]
  depends_on = [
    resource.local_file.ansible_config,
    resource.proxmox_virtual_environment_vm.k8s_worker_nodes
  ]
}
