packer {
  required_plugins {
    proxmox = {
      version = "=> 1"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

variable "hostname" {
  type    = string
  default = "seclab-win-server"
}

variable "proxmox_node" {
  type    = string
  default = "proxmox"
}

variable "vault_path" {
  type    = string
  default = "/seclab/data/seclab/"
}

locals {
  username          = vault("${var.vault_path}", "seclab_user")
  password          = vault("${var.vault_path}", "seclab_windows_password")
  proxmox_api_id    = vault("${var.vault_path}", "proxmox_api_id")
  proxmox_api_token = vault("${var.vault_path}", "proxmox_api_token")

  additional_iso_files = [
    {
      device       = "ide3"
      iso_file     = "local:iso/Autounattend-win-server-2019.iso"
      iso_checksum = "sha256:bf44c536d84e62ae5b1d83eca44b4725644578ddeb11d55f78fe0f4e5849f196"
      unmount      = true
    },
    {
      device       = "sata0"
      iso_file     = "local:iso/virtio.iso"
      iso_checksum = "sha256:8a066741ef79d3fb66e536fb6f010ad91269364bd9b8c1ad7f2f5655caf8acd8"
      unmount      = true
    }
  ]
}

source "proxmox-iso" "seclab-win-server" {
  proxmox_url              = "https://${var.proxmox_node}:8006/api2/json"
  node                     = var.proxmox_node
  username                 = local.proxmox_api_id
  token                    = local.proxmox_api_token
  iso_file                 = "local:iso/Win-Server-2019.iso"
  iso_checksum             = "sha256:549bca46c055157291be6c22a3aaaed8330e78ef4382c99ee82c896426a1cee1"
  insecure_skip_tls_verify = true
  communicator             = "ssh"
  ssh_username             = local.username
  ssh_password             = local.password
  ssh_timeout              = "30m"
  qemu_agent               = true
  cores                    = 2
  memory                   = 4096
  vm_name                  = "seclab-win-server"
  template_description     = "Base Seclab Windows Server"

  dynamic "additional_iso_files" {
    for_each = local.additional_iso_files
    content {
      device       = additional_iso_files.value.device
      iso_file     = additional_iso_files.value.iso_file
      iso_checksum = additional_iso_files.value.iso_checksum
      unmount      = additional_iso_files.value.unmount
    }
  }

  network_adapters {
    bridge = "vmbr2"
  }

  disks {
    type         = "virtio"
    disk_size    = "50G"
    storage_pool = "local-lvm"
  }
  scsi_controller = "virtio-scsi-pci"
}

build {
  sources = ["sources.proxmox-iso.seclab-win-server"]
  provisioner "windows-shell" {
    inline = [
      "ipconfig",
    ]
  }
}
