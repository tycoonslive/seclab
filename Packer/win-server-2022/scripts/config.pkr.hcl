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

locals {
  username          = vault("/seclab/data/seclab/", "seclab_user")
  password          = vault("/seclab/data/seclab/", "seclab_windows_password")
  proxmox_api_id    = vault("/seclab/data/seclab/", "proxmox_api_id")
  proxmox_api_token = vault("/seclab/data/seclab/", "proxmox_api_token")
}

source "proxmox-iso" "seclab-win2022-server" {
  proxmox_url              = "https://${var.proxmox_node}:8006/api2/json"
  node                     = var.proxmox_node
  username                 = local.proxmox_api_id
  token                    = local.proxmox_api_token
  ssh_username             = local.username
  ssh_password             = local.password
  ssh_wait_timeout         = "30m"
  insecure_skip_tls_verify = true
  

  # VM Configuration
  vm_name                  = "seclab-win2022-server"
  template_description     = "Base Seclab Windows Server 2022"
  qemu_agent               = true
  cores                    = 4
  memory                   = 4096
  machine                  = "q35"
  bios                     = "ovmf"

  # EFI Configuration
  efi_config {
    efi_storage_pool  = "ISO"
    efi_type         = "4m"
    pre_enrolled_keys = true
  }

  # Boot and Additional ISOs
  boot_iso {
    iso_file = "ISO:iso/Windows-srv-2022-fr-fr.iso"
  }



  additional_iso_files {
    type    = "sata"
    index   = 0
    iso_file = "local:iso/virtio-win-0.1.262.iso"
    unmount = true
  }

  additional_iso_files {
    type    = "sata"
    index   = 1
    iso_file = "local:iso/Autounattend-2022.iso"
    unmount = true
  }

  # Network Configuration
  network_adapters {
    bridge   = "vmbr2"
    model    = "virtio"
    firewall = false
  }

  # Disk Configuration
  scsi_controller = "virtio-scsi-single"
  
  disks {
    type         = "scsi"
    disk_size    = "50G"
    storage_pool = "ISO"
    format       = "qcow2"
    ssd          = true
    discard      = true
  }
}

build {
  sources = ["source.proxmox-iso.seclab-win2022-server"]
  
  provisioner "windows-shell" {
    inline = [
      "ipconfig",
    ]
  }
}
