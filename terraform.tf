terraform {
  required_version = ">=1.7.0"

  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.48.1"
    }

    talos = {
      source  = "siderolabs/talos"
      version = "0.6.1"
    }

    http = {
      source  = "hashicorp/http"
      version = ">=3.4.2"
    }

    helm = {
      source  = "hashicorp/helm"
      version = ">=2.12.1"
    }

    tls = {
      source  = "hashicorp/tls"
      version = ">=4.0.5"
    }
  }
}

provider "hcloud" {
  token         = var.hcloud_token
  poll_interval = "2s"
}

provider "helm" {
  kubernetes {
    config_path = "kubeconfig"
  }
}
