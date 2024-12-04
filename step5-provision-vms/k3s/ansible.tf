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

variable "k3s_vip_ip" {
  description = "Floating virtual IP of the external loadbalancer"
  type        = string
}

variable "k3s_vip_hostname" {
  description = "Hostname associated with the floating VIP"
  type        = string
}

variable "k3s_vip_domain" {
  description = "The site domain"
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
resource "ansible_group" "k3s_master" {
  name     = "k3s_master"
  children = [for vm in var.vms : vm.hostname if vm.role == "k3s_master"]
  depends_on = [
    resource.proxmox_virtual_environment_vm.k3s_master
  ]
}

resource "ansible_group" "k3s_servers" {
  name     = "k3s_servers"
  children = [for vm in var.vms : vm.hostname if var.want_k3s_servers && vm.role == "k3s_server"]
  depends_on = [
    resource.proxmox_virtual_environment_vm.k3s_servers
  ]
}

resource "ansible_group" "k3s_agents" {
  name     = "k3s_agents"
  children = [for vm in var.vms : vm.hostname if var.want_k3s_agents && vm.role == "k3s_agent"]
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
resource "ansible_host" "k3s_master" {
  for_each = { for vm in var.vms : vm.hostname => vm if vm.role == "k3s_master" }
  name     = each.key
  groups   = ["k3s_master"]
  depends_on = [
    resource.proxmox_virtual_environment_vm.k3s_master
  ]
}

resource "ansible_host" "k3s_servers" {
  for_each = { for vm in var.vms : vm.hostname => vm if var.want_k3s_servers && vm.role == "k3s_server" }
  name     = each.key
  groups   = ["k3s_servers"]
  depends_on = [
    resource.proxmox_virtual_environment_vm.k3s_servers
  ]
}

resource "ansible_host" "k3s_agents" {
  for_each = { for vm in var.vms : vm.hostname => vm if var.want_k3s_agents && vm.role == "k3s_agent" }
  name     = each.key
  groups   = ["k3s_agent"]
  depends_on = [
    resource.proxmox_virtual_environment_vm.k3s_agents
  ]
}
