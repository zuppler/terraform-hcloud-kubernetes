locals {
  hcloud_load_balancer_location = coalesce(
    var.hcloud_load_balancer_location,
    length(local.worker_nodepools) > 0 ? local.worker_nodepools[0].location : null,
    length(local.autoscaler_nodepools) > 0 ? local.autoscaler_nodepools[0].location : null,
    local.control_plane_nodepools[0].location
  )

  kube_api_load_balancer_private_ipv4 = cidrhost(hcloud_network_subnet.load_balancer.ip_range, -2)
  kube_api_load_balancer_public_ipv4  = var.kube_api_load_balancer_enabled ? hcloud_load_balancer.kube_api[0].ipv4 : null
  kube_api_load_balancer_public_ipv6  = var.kube_api_load_balancer_enabled ? hcloud_load_balancer.kube_api[0].ipv6 : null
  kube_api_load_balancer_name         = "${var.cluster_name}-kube-api"
  kube_api_load_balancer_location     = local.control_plane_nodepools[0].location

  kube_api_load_balancer_public_network_enabled = coalesce(
    var.kube_api_load_balancer_public_network_enabled,
    var.cluster_access == "public"
  )

  ingress_load_balancer_private_ipv4 = cidrhost(hcloud_network_subnet.load_balancer.ip_range, -4)
  ingress_load_balancer_public_ipv4  = var.ingress_nginx_enabled ? hcloud_load_balancer.ingress[0].ipv4 : null
  ingress_load_balancer_public_ipv6  = var.ingress_nginx_enabled ? hcloud_load_balancer.ingress[0].ipv6 : null
  ingress_load_balancer_hostname     = var.ingress_nginx_enabled ? "static.${join(".", reverse(split(".", local.ingress_load_balancer_public_ipv4)))}.clients.your-server.de" : ""
  ingress_load_balancer_name         = "${var.cluster_name}-ingress"
  ingress_load_balancer_location     = local.hcloud_load_balancer_location
}

# Kubernetes API Load Balancer
resource "hcloud_load_balancer" "kube_api" {
  count = var.kube_api_load_balancer_enabled ? 1 : 0

  name               = local.kube_api_load_balancer_name
  location           = local.kube_api_load_balancer_location
  load_balancer_type = "lb11"
  delete_protection  = var.cluster_delete_protection

  algorithm {
    type = "round_robin"
  }

  labels = {
    "cluster" = var.cluster_name
    "role"    = "kube-api"
  }
}

resource "hcloud_load_balancer_network" "kube_api" {
  count = var.kube_api_load_balancer_enabled ? 1 : 0

  load_balancer_id        = hcloud_load_balancer.kube_api[0].id
  enable_public_interface = local.kube_api_load_balancer_public_network_enabled
  subnet_id               = hcloud_network_subnet.load_balancer.id
  ip                      = local.kube_api_load_balancer_private_ipv4
}

resource "hcloud_load_balancer_target" "kube_api" {
  count = var.kube_api_load_balancer_enabled ? 1 : 0

  load_balancer_id = hcloud_load_balancer.kube_api[0].id
  type             = "label_selector"
  use_private_ip   = true

  label_selector = join(",",
    [
      "cluster=${var.cluster_name}",
      "role=control-plane"
    ]
  )

  depends_on = [hcloud_load_balancer_network.kube_api]
}

resource "hcloud_load_balancer_service" "kube_api" {
  count = var.kube_api_load_balancer_enabled ? 1 : 0

  load_balancer_id = hcloud_load_balancer.kube_api[0].id
  protocol         = "tcp"
  listen_port      = local.kube_api_port
  destination_port = local.kube_api_port

  health_check {
    protocol = "http"
    port     = local.kube_api_port
    interval = 3
    timeout  = 2
    retries  = 2

    http {
      path         = "/version"
      response     = "Status"
      tls          = true
      status_codes = ["401"]
    }
  }

  depends_on = [hcloud_load_balancer_target.kube_api]
}

# Ingress Load Balancer
resource "hcloud_load_balancer" "ingress" {
  count = var.ingress_nginx_enabled ? 1 : 0

  name               = local.ingress_load_balancer_name
  location           = local.ingress_load_balancer_location
  load_balancer_type = var.ingress_load_balancer_type
  delete_protection  = var.cluster_delete_protection

  algorithm {
    type = var.ingress_load_balancer_algorithm
  }

  labels = {
    "cluster" = var.cluster_name
    "role"    = "ingress"
  }

  lifecycle {
    ignore_changes = [
      labels
    ]
  }
}

resource "hcloud_load_balancer_network" "ingress" {
  count = var.ingress_nginx_enabled ? 1 : 0

  load_balancer_id        = hcloud_load_balancer.ingress[0].id
  enable_public_interface = var.ingress_load_balancer_public_network_enabled
  subnet_id               = hcloud_network_subnet.load_balancer.id
  ip                      = local.ingress_load_balancer_private_ipv4
}
