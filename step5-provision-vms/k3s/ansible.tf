###############################################################################
###############################################################################
##
##  Variable Definitions
##
###############################################################################
###############################################################################
variable "k3s_token" {
  description = "Join token for K3S (any string)"
  type        = string
}

variable "k3s_version" {
  description = "Version of K3S to install"
  type        = string
}

variable "k3s_api_url" {
  description = "Version of K3S to install"
  type        = string
}

variable "k3s_local_kubeconfig_path" {
  description = "Path to kubeconfig on the Ansible controller"
  type        = string
}


###############################################################################
###############################################################################
##
##  Ansible config file
##
###############################################################################
###############################################################################
resource "local_file" "ansible_config" {
  filename        = "${path.module}/ansible.cfg"
  file_permission = "0644"
  content         = <<EOF
[defaults]
inventory=.terraform-dynamic-inventory.yml
remote_user=${var.ci_user}
host_key_checking=false
EOF
}

###############################################################################
###############################################################################
##
##  Dynamic Ansible Inventory Groups
##
###############################################################################
###############################################################################
resource "ansible_group" "k3s_control_plane_nodes" {
  name = "k3s_control_plane_nodes"
  variables = {
    ansible_ssh_user = var.ci_user
  }
  depends_on = [
    resource.proxmox_virtual_environment_vm.k3s_servers
  ]
}

resource "ansible_group" "k3s_worker_nodes" {
  name = "k3s_worker_nodes"
  variables = {
    ansible_ssh_user = var.ci_user
  }
  depends_on = [
    resource.proxmox_virtual_environment_vm.k3s_agents
  ]
}

###############################################################################
###############################################################################
##
##  Dynamic Ansible Inventory Hosts
##
###############################################################################
###############################################################################
resource "ansible_host" "k3s_first_control_plane" {
  for_each = { for vm in var.vms : vm.hostname => vm if vm.role == "k3s_initial_cp" }
  name     = each.key
  groups   = ["k3s_control_plane_nodes", "k3s_first_control_plane"]
  depends_on = [
    resource.proxmox_virtual_environment_vm.k3s_initial_cp
  ]
}

resource "ansible_host" "k3s_additional_control_planes" {
  for_each = { for vm in var.vms : vm.hostname => vm if vm.role == "k3s_server" }
  name     = each.key
  groups   = ["k3s_control_plane_nodes", "k3s_additional_control_planes"]
  depends_on = [
    resource.proxmox_virtual_environment_vm.k3s_servers
  ]
}

resource "ansible_host" "k3s_workers" {
  for_each = { for vm in var.vms : vm.hostname => vm if vm.role == "k3s_agent" }
  name     = each.key
  groups   = ["k3s_worker_nodes"]
  depends_on = [
    resource.proxmox_virtual_environment_vm.k3s_agents
  ]
}
