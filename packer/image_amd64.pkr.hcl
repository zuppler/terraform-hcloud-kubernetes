variable "cluster_name" {
  type = string
}

variable "server_location" {
  type    = string
  default = "fsn1"
}

variable "talos_version" {
  type = string
}

variable "talos_schematic_id" {
  type = string
}

variable "talos_image_url" {
  type = string
}

locals {
  download_image = "wget --timeout=5 --waitretry=5 --tries=5 --retry-connrefused --inet4-only -O /tmp/talos.raw.xz '${var.talos_image_url}'"

  write_image = <<-EOT
    set -ex
    
    echo 'Talos image loaded, writing to disk...'
    xz -d -c /tmp/talos.raw.xz | dd of=/dev/sda && sync
    echo 'done.'
  EOT

  clean_up = <<-EOT
    set -ex
    
    echo "Cleaning-up..."
    rm -rf /etc/ssh/ssh_host_*
  EOT
}

# Source for the Talos AMD64 image
source "hcloud" "amd64_builder" {
  rescue       = "linux64"
  image        = "debian-11"
  location     = var.server_location
  server_type  = "cx22"
  ssh_username = "root"

  snapshot_name   = "Talos Linux AMD64 for ${var.cluster_name}"
  snapshot_labels = {
    cluster            = var.cluster_name,
    os                 = "talos",
    talos_version      = var.talos_version,
    talos_schematic_id = substr(var.talos_schematic_id, 0, 32)
  }
}

# Build the Talos AMD64 snapshot
build {
  sources = ["source.hcloud.amd64_builder"]

  provisioner "shell" {
    inline = [local.download_image]
  }
  provisioner "shell" {
    inline = [local.write_image]
  }
  provisioner "shell" {
    inline = [local.clean_up]
  }
}
