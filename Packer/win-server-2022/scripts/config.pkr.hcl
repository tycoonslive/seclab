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
source "proxmox-iso" "seclab-win2022-server" {
  proxmox_url              = "https://${var.proxmox_node}:8006/api2/json"
  node                     = var.proxmox_node
  username                 = local.proxmox_api_id
  token                    = local.proxmox_api_token
  iso_file                 = "local:iso/Win-Server-2022.iso"
  iso_checksum             = "sha256:checksum-value"
  insecure_skip_tls_verify = true
  communicator             = "ssh"
  ssh_username             = local.username
  ssh_password             = local.password
  ssh_timeout              = "30m"
  qemu_agent               = true
  cores                    = 4
  memory                   = 4096
  vm_name                  = "seclab-win2022-server"
  template_description     = "Base Seclab Windows Server 2022"

  # Configuration TPM
  tpm_config {
    storage = "local-lvm"
    version = "v2.0"
  }

  network_adapters {
    bridge = "vmbr2"
  }

  disks {
    type         = "virtio"
    disk_size    = "50G"
    storage_pool = "loacal-lvm"
  }
  scsi_controller = "virtio-scsi-pci"
}
