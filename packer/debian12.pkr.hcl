#==========================================
# Variables specific to Proxmox
#==========================================
variable "pm_api_url" {
  type    = string
}
variable "pm_api_token_secret" {
  type    = string
}
variable "pm_api_token_id" {
  type    = string
}
variable "pm_iso_storage_pool" {
  type    = string
}


#==========================================
# Variables specific to running packer in a container
#==========================================
variable "container_host_ip" {
  type    = string
}


#==========================================
# Variables specific to the site
#==========================================
variable "domain" {
  type    = string
}


#==========================================
# Variables specific to the VM template
#==========================================
variable "vm_name" {
  type    = string
}
variable "vm_id" {
  type    = string
}
variable "vm_node" {
  type    = string
}
variable "vm_storage_pool" {
  type    = string
}
variable "vm_installer_file" {
  type    = string
}
variable "vm_vlan" {
  type    = string
  default = ""
}
variable "cores" {
  type    = string
  default = "2"
}
variable "disk_size" {
  type    = string
  default = "20G"
}
variable "memory" {
  type    = string
  default = "2048"
}


#==========================================
# Variables for the provisioning account
#==========================================
variable "cm_username" {
  type    = string
}
variable "cm_gecos" {
  type    = string
}
variable "cm_password" {
  type    = string
}
variable "keydir" {
  type    = string
}

#==========================================
# Variables for the installer file template
#==========================================
variable "country" {
  type    = string
  default = "US"
}
variable "keyboard" {
  type    = string
  default = "us"
}
variable "language" {
  type    = string
  default = "en"
}
variable "locale" {
  type    = string
  default = "en_US.UTF-8"
}
variable "mirror" {
  type    = string
  default = "ftp.us.debian.org"
}
variable "system_clock_in_utc" {
  type    = string
  default = "true"
}
variable "timezone" {
  type    = string
  default = "UTC"
}
variable "http_port_max" {
  type    = string
  default = "8300"
}
variable "http_port_min" {
  type    = string
  default = "8300"
}
variable "start_retry_timeout" {
  type    = string
  default = "5m"
}


source "proxmox-iso" "debian12-preseed" {
  bios         = "ovmf"
  boot_command = [
    "<wait><wait><wait>c<wait><wait><wait>",
    "linux /install.amd/vmlinuz ",
    "auto=true ",
    "url=http://${var.container_host_ip}:{{ .HTTPPort }}/${var.vm_installer_file} ",
    "hostname=${var.vm_name} ",
    "domain=${var.domain} ",
    "interface=auto ",
    "vga=788 noprompt quiet --<enter>",
    "initrd /install.amd/initrd.gz<enter>",
    "boot<enter>"
  ]
  boot_wait    = "20s"
  cores        = "${var.cores}"
  cpu_type     = "x86-64-v2-AES"
  disable_kvm  = false
  disks {
    disk_size         = "${var.disk_size}"
    io_thread         = true
    storage_pool      = "${var.vm_storage_pool}"
    type              = "scsi"
  }
  efi_config {
    efi_storage_pool  = "${var.vm_storage_pool}"
    efi_type          = "4m"
    pre_enrolled_keys = true
  }
  http_content         = { "/${var.vm_installer_file}" = templatefile(var.vm_installer_file, { var = var }) }
  http_port_max        = var.http_port_max
  http_port_min        = var.http_port_min
  insecure_skip_tls_verify = true
  iso_file                 = "${var.pm_iso_storage_pool}:iso/debian-12.1.0-amd64-netinst.iso"
  machine                  = "pc"
  memory                   = "${var.memory}"
  network_adapters {
    bridge = "vmbr0"
    model  = "virtio"
    vlan_tag = "${var.vm_vlan}"
    firewall = true
    mac_address = "repeatable"
  }
  node                 = "${var.vm_node}"
  os                   = "l26"
  onboot               = false
  proxmox_url          = "${var.pm_api_url}"
  qemu_agent           = true
  scsi_controller      = "virtio-scsi-single"
  sockets              = 1
  ssh_password         = "${var.cm_password}"
  ssh_timeout          = "120m"
  ssh_username         = "${var.cm_username}"
  template_description = "Debian 12 (${var.vm_installer_file}), generated on ${timestamp()}"
  template_name        = "${var.vm_name}"
  token                = "${var.pm_api_token_secret}"
  unmount_iso          = true
  username             = "${var.pm_api_token_id}"
  vga {
    type = "qxl"
    memory = 32
  }
  vm_id                = "${var.vm_id}"
  vm_name              = "${var.vm_name}"
}

build {
  sources = ["source.proxmox-iso.debian12-preseed"]

  provisioner "shell" {
    binary              = false
    execute_command     = "echo '${var.cm_password}' | {{ .Vars }} sudo -E -S '{{ .Path }}'"
    expect_disconnect   = true
    inline              = [
      "echo '${var.cm_username} ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/99${var.cm_username}",
      "chmod 0440 /etc/sudoers.d/99${var.cm_username}",
      "echo 'auto ens18\niface ens18 inet dhcp\n' > /etc/network/interfaces.d/ens18",
      "mkdir -p /home/${var.cm_username}/.ssh/",
      "chown -R ${var.cm_username}:${var.cm_username} /home/${var.cm_username}/.ssh/"
    ]
    inline_shebang      = "/bin/sh -e"
    skip_clean          = false
    start_retry_timeout = "${var.start_retry_timeout}"
  }

  provisioner "file" {
    source      = "${var.keydir}/${var.cm_username}.pub"
    destination = "/home/${var.cm_username}/.ssh/authorized_keys2"
  }

  provisioner "shell" {
    binary              = false
    execute_command     = "echo '${var.cm_password}' | {{ .Vars }} sudo -E -S '{{ .Path }}'"
    expect_disconnect   = true
    inline              = [
      "apt-get --yes update",
      "apt-get --yes dist-upgrade",
      "apt-get --yes clean"
    ]
    inline_shebang      = "/bin/sh -e"
    skip_clean          = false
    start_retry_timeout = "${var.start_retry_timeout}"
  }
}
