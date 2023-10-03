# See https://github.com/Telmate/terraform-provider-proxmox/blob/master/docs/resources/vm_qemu.md
# for an explanation of the contents of this file.
# proxmox_vm_qemu.host1:
resource "proxmox_vm_qemu" "vms" {
  count = var.vm_count
  lifecycle {
    ignore_changes = [
      # The packer generated templates contain a note with a timestamp
      # as to when the template was created.  Changes in this note can
      # be ignored.
      desc,
    ]
  }
  name                   = "debian12-vm${count.index}"
  clone                  = "debian12-minimal"
  target_node            = "${var.target_node}"
  agent                  = 1
  bios                   = "ovmf"
  boot                   = "order=scsi0;ide2;net0"
  cores                  = "${var.cores}"
  define_connection_info = true
  full_clone             = false
  memory                 = "${var.memory}"
  oncreate               = true
  qemu_os                = "l26"
  scsihw                 = "virtio-scsi-single"
  disk {
    backup   = true
    discard  = "on"
    iothread = 1
    size     = "${var.disk_size}"
    ssd      = 1
    storage  = "${var.storage}"
    type     = "scsi"
  }
  network {
    bridge = "vmbr0"
    model  = "virtio"
    tag    = "${var.vlan}"
  }
}

resource "local_file" "ansible_inventory" {
  content = templatefile("ansible-inventory.tftpl", { vmlist = proxmox_vm_qemu.vms[*]})
  filename = "../ansible/terraform-inventory.yml"
}
